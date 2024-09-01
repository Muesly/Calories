//
//  DataView.swift
//  Calories
//
//  Created by Tony Short on 05/05/2024.
//

import HealthKit
import SwiftUI

struct DataView: View {
    private let viewModel: DataViewModel
    
    @State var text = "Calculating"
    
    init(healthStore: HealthStore) {
        self.viewModel = DataViewModel(healthStore: healthStore, segmentLengthInDays: 14)
    }
    var body: some View {
        Text(text)
            .onAppear {
                Task {
                    text = await viewModel.report()
                }
            }
    }
}

enum DataViewError: Error {
    case failedToGetCaloriesConsumed
    case failedToGetFirstCaloriesConsumedItem
}

struct ReportedCalorieDataPoint: Equatable {
    let date: Date
    let calories: Int
}

struct ReportedWeightDataPoint: Equatable {
    let date: Date
    let weight: Int
}

struct Segment: Equatable {
    var caloriesConsumed: Int
    let bmrTotal: Int
    let activeTotal: Int
    let startWeight: Int
    let endWeight: Int
    let startDate: Date
    let endDate: Date

    var activeFactor: Double = 1.0
    var bmrFactor: Double = 1.0
    var calorieFactor: Double = 1.0

    var expectedWeightLoss: Double {
        let bmr = Double(bmrTotal) * Double(bmrFactor)
        let active = Double(activeTotal) * Double(activeFactor)
        let calories = Double(caloriesConsumed) * Double(calorieFactor)
        return (bmr + active - calories) / 3500
    }
    
    var actualWeightLoss: Int {
        return startWeight - endWeight
    }
    
    var weightVariance: Double {
        return expectedWeightLoss - Double(actualWeightLoss)
    }
}

struct CalculatedData: Equatable {
    let segments: [Segment]
    var startDate: Date? { segments.first?.startDate }
    var endDate: Date? {segments.last?.endDate }
}

class DataViewModel {
    let healthStore: HealthStore
    let segmentLengthInDays: Int
    
    init(healthStore: HealthStore, segmentLengthInDays: Int) {
        self.healthStore = healthStore
        self.segmentLengthInDays = segmentLengthInDays
    }
    
    private func getConsumptionDataPoints() async throws -> [ReportedCalorieDataPoint] {
        let currentDate = Date()
        let fromDateComponents = NSDateComponents()
        fromDateComponents.year = 2023
        fromDateComponents.month = 1
        fromDateComponents.day = 1
        let fromDate = Calendar.current.date(from: fromDateComponents as DateComponents)!
        let consumptionDataPoints: [ReportedCalorieDataPoint]
        do {
            consumptionDataPoints = try await healthStore.caloriesConsumedAllDataPoints(fromDate: fromDate, toDate: currentDate, applyModifier: false).map {
                .init(date: $0.0, calories: $0.1)
            }
        } catch {
            throw DataViewError.failedToGetCaloriesConsumed
        }
        return consumptionDataPoints
    }

    private func createSegment(consumptionDataPoints: [ReportedCalorieDataPoint],
                               bmrDataPoints: [ReportedCalorieDataPoint],
                               activeDataPoints: [ReportedCalorieDataPoint],
                               startWeight: Int,
                               weightDataPoints: [ReportedWeightDataPoint],
                               startDate: Date,
                               endDate: Date) -> Segment {
        let caloriesConsumed = consumptionDataPoints.reduce(0) {
            return $0 + $1.calories
        }
        
        let bmrTotal = bmrDataPoints.reduce(0) {
            if $1.date >= startDate && $1.date < endDate {
                return $0 + $1.calories
            } else {
                return $0
            }
        }

        let activeTotal = activeDataPoints.reduce(0) {
            if $1.date >= startDate && $1.date < endDate {
                return $0 + $1.calories
            } else {
                return $0
            }
        }

        let lastWeightInDataPoints = weightDataPoints.last(where: { $0.date < endDate })?.weight ?? 0

        return Segment(caloriesConsumed: caloriesConsumed,
                       bmrTotal: bmrTotal,
                       activeTotal: activeTotal,
                       startWeight: startWeight,
                       endWeight: lastWeightInDataPoints,
                       startDate: startDate,
                       endDate: endDate)
    }
    
    private func createSegments(firstRecordedDate: Date,
                                consumptionDataPoints: [ReportedCalorieDataPoint],
                                bmrDataPoints: [ReportedCalorieDataPoint],
                                activeDataPoints: [ReportedCalorieDataPoint],
                                weightDataPoints: [ReportedWeightDataPoint]) -> [Segment] {
        var segments = [Segment]()
        let segmentLength = Double(segmentLengthInDays * 86400)
        var nextSegmentDate = firstRecordedDate + segmentLength
        var currentDataPoints = [ReportedCalorieDataPoint]()
        var startWeight = weightDataPoints.first?.weight ?? 0
        consumptionDataPoints.forEach { dataPoint in
            if dataPoint.date >= nextSegmentDate {
                let segment = createSegment(consumptionDataPoints: currentDataPoints,
                                            bmrDataPoints: bmrDataPoints,
                                            activeDataPoints: activeDataPoints,
                                            startWeight: startWeight,
                                            weightDataPoints: weightDataPoints,
                                            startDate: nextSegmentDate - segmentLength,
                                            endDate: nextSegmentDate)
                segments.append(segment)
                startWeight = segment.endWeight
                nextSegmentDate += segmentLength
                currentDataPoints.removeAll()
            }
            currentDataPoints.append(dataPoint)
        }
        return segments
    }
    
    func calculate() async throws -> CalculatedData {
        let consumptionDataPoints = try await getConsumptionDataPoints()
        guard let firstRecordedDate = consumptionDataPoints.first?.date,
              let lastRecordedDate = consumptionDataPoints.last?.date else {
            throw DataViewError.failedToGetFirstCaloriesConsumedItem
        }

        let bmrDataPoints = try await healthStore.bmrBetweenDates(fromDate: firstRecordedDate,
                                                                  toDate: lastRecordedDate,
                                                                  applyModifier: false).map {
            ReportedCalorieDataPoint(date: $0.0, calories: $0.1)
        }

        let activeDataPoints = try await healthStore.activeBetweenDates(fromDate: firstRecordedDate,
                                                                        toDate: lastRecordedDate,
                                                                        applyModifier: false).map {
            ReportedCalorieDataPoint(date: $0.0, calories: $0.1)
        }

        let weightDataPoints = try await healthStore.weightBetweenDates(fromDate: firstRecordedDate,
                                                                        toDate: lastRecordedDate).map {
            ReportedWeightDataPoint(date: $0.0, weight: $0.1)
        }

        let segments = createSegments(firstRecordedDate: firstRecordedDate,
                                      consumptionDataPoints: consumptionDataPoints,
                                      bmrDataPoints: bmrDataPoints,
                                      activeDataPoints: activeDataPoints,
                                      weightDataPoints: weightDataPoints)

        let calculatedData = CalculatedData(segments: segments)
        return calculatedData
    }
    
    private func formattedString(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        let number = NSNumber(value: amount)
        return formatter.string(from: number)!
    }
    
    func report() async -> String {
        do {
            let calculatedData = try await calculate()
            var text = ""
            let startingFactor = 0.5
            let factorLimit = 1.5
            var bmrFactor, activeFactor, calorieFactor: Double
            var lowestVariance = 9999.0
            var lowestBMRFactor = 999.0
            var lowestActiveFactor = 999.0
            var lowestCalorieFactor = 999.0
            
            bmrFactor = startingFactor
            for _ in 1...10 {
                activeFactor = startingFactor
                for _ in 1...10 {
                    calorieFactor = startingFactor
                    for _ in 1...10 {
                        let varianceAverage = calculatedData.segments.reduce(0.0) {
                            var segment = $1
                            segment.activeFactor = activeFactor
                            segment.bmrFactor = bmrFactor
                            segment.calorieFactor = calorieFactor
                            return $0 + segment.weightVariance
                        } / Double(calculatedData.segments.count)

                        if abs(varianceAverage) < lowestVariance {
                            lowestVariance = abs(varianceAverage)
                            lowestBMRFactor = bmrFactor
                            lowestActiveFactor = activeFactor
                            lowestCalorieFactor = calorieFactor
                        }
                        calorieFactor += 0.1
                        if calorieFactor > factorLimit {
                            break
                        }
                    }
                    activeFactor += 0.1
                    if activeFactor > factorLimit {
                        break
                    }
                }
                bmrFactor += 0.1
                if bmrFactor > factorLimit {
                    break
                }
            }
               
            text += "Best ratio:\nBMR \(lowestBMRFactor)\nActive: \(lowestActiveFactor)\nCalorie: \(lowestCalorieFactor)\nVariance: \(lowestVariance)\n"

//            bmrFactor = 1.0
//            activeFactor = 0.8
//            calorieFactor = 1.1
//
//            let bmr = calculatedData.segments.reduce(0) { $0 + ((Double)($1.bmrTotal) * bmrFactor) }
//            let active = calculatedData.segments.reduce(0) { $0 + ((Double)($1.activeTotal) * activeFactor) }
//            let calories = calculatedData.segments.reduce(0) { $0 + ((Double)($1.caloriesConsumed) * calorieFactor) }
//            let expectedWeightLoss = (bmr + active - calories) / 3500

            return text
        } catch {
            return "Error"
        }
    }
}
