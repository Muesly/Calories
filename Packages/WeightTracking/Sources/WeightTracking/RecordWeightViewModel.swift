//
//  RecordWeightViewModel.swift
//  Calories
//
//  Created by Tony Short on 20/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

struct WeightDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let weight: Int
    let deficit: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.date == rhs.date) && (lhs.weight == rhs.weight) && (lhs.deficit == rhs.deficit)
    }

    static func weekStr(from fromDate: Date, to toDate: Date) -> String {
        let toDateComps = Calendar.current.dateComponents([.day, .month, .year], from: toDate)
        let monthStr = Calendar.current.shortMonthSymbols[(toDateComps.month ?? 1) - 1]
        return "\(toDateComps.day ?? 0) \(monthStr) \((toDateComps.year ?? 0) - 2000)"
    }
}

@Observable
@MainActor
class RecordWeightViewModel: ObservableObject {
    let healthStore: HealthStore
    var weightData: [WeightDataPoint] = []
    var latestWeight: Int = 0
    var originalWeight = 0

    init(healthStore: HealthStore) {
        self.healthStore = healthStore
    }

    private func startOfWeek(_ date: Date = Date()) -> Date {
        return date.startOfWeek
    }

    func fetchWeightData(date: Date, numWeeks: Int? = nil) async throws {
        try await healthStore.authorize()
        var endDate = date
        var startDate = startOfWeek(date)
        var weightData = [WeightDataPoint]()
        var numEmptyConsecutiveWeeks = 0
        var numNilWeeks = 0
        var numWeeksReported = 0

        repeat {  // For last x weeks
            // Find most recent data point in last 7 days from now
            if let weightDataPoint = try await healthStore.weight(
                fromDate: startDate,
                toDate: endDate)
            {
                do {
                    let deficit = try await fetchWeeklyDeficit(forDate: endDate)
                    weightData.append(
                        WeightDataPoint(date: endDate, weight: weightDataPoint, deficit: deficit))
                    numEmptyConsecutiveWeeks = 0
                } catch RecordWeightErrors.noCaloriesReported {
                    if numEmptyConsecutiveWeeks == 0 {
                        // Scenario at start of week where no calories have been reported but a weight measurement has
                        weightData.append(
                            WeightDataPoint(date: endDate, weight: weightDataPoint, deficit: 0))
                    }
                    numEmptyConsecutiveWeeks += 1
                    if numEmptyConsecutiveWeeks > 1 {
                        // Break out when we have a significant break in calories reporting
                        // to capture just the current weight reporting period
                        break
                    }
                } catch {
                    break
                }
            } else {
                numNilWeeks += 1
                if numNilWeeks > 52 {
                    // Break out when we have a significant break in weight entries
                    // e.g. in UI tests where we never change calories returned
                    break
                }
            }
            if let numWeeks {
                numWeeksReported += 1
                if numWeeksReported == numWeeks {
                    break
                }
            }
            // Move to start of day, then go to prevous week
            endDate = startDate.addingTimeInterval(-1)
            startDate = endDate.startOfWeek
        } while true
        self.weightData = weightData.reversed()
        self.latestWeight = Int(weightData.first?.weight ?? 0)
        if originalWeight == 0 {
            originalWeight = self.latestWeight
        }
    }

    func weekStr(forDataPoint dataPoint: WeightDataPoint) -> String {
        guard let firstRecordedDate = weightData.first?.date else {
            return ""
        }
        return WeightDataPoint.weekStr(
            from: firstRecordedDate.startOfWeek, to: dataPoint.date.startOfWeek)
    }

    func weightStr(_ weight: Double) -> String {
        let stones = Int(weight) / 14
        let pounds = Int(weight) % 14
        return "\(stones)st \(pounds)"
    }

    var currentWeight: String {
        let lastWeight = latestWeight
        let stone = Int(lastWeight / 14)
        let pounds = Int(lastWeight) % 14
        return "\(stone) st, \(pounds) lbs"
    }

    var totalLoss: String {
        let startingWeight = Int(weightData.first?.weight ?? 0)
        let lastWeight = latestWeight

        let down = "\u{2193}"
        let up = "\u{2191}"
        let directionStr = lastWeight > startingWeight ? up : down

        let upDownPounds = Int(abs(lastWeight - startingWeight))
        let upDownStone = upDownPounds / 14
        let upDownPoundsLeft = upDownPounds % 14
        return "Progress: \(upDownStone) stone \(upDownPoundsLeft) lbs \(directionStr)"
    }

    var hasLostWeight: Bool {
        originalWeight > self.latestWeight
    }

    func decreaseWeight() {
        latestWeight -= 1
    }

    func increaseWeight() {
        latestWeight += 1
    }

    func applyNewWeight(date: Date) async throws {
        try await healthStore.addWeightEntry(WeightEntry(weight: latestWeight, timeRecorded: date))
    }

    func fetchWeeklyDeficit(forDate: Date) async throws -> Int {
        var burntCalories = 0
        var consumedCalories = 0
        do {
            var date = forDate
            for _ in 0..<7 {
                let consumedCaloriesForDay = try await healthStore.caloriesConsumed(date: date)
                if consumedCaloriesForDay == 0 {
                    throw RecordWeightErrors.noCaloriesReported
                }
                consumedCalories += consumedCaloriesForDay

                let bmr = try await healthStore.bmr(date: date)
                let exercise = try await healthStore.exercise(date: date)
                burntCalories += bmr + exercise

                // Move to end of previous day
                date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)
            }
        } catch RecordWeightErrors.noCaloriesReported {
            throw RecordWeightErrors.noCaloriesReported
        } catch {
            print("Failed to fetch burnt or consumed data")
        }
        return consumedCalories - burntCalories
    }
}

enum RecordWeightErrors: Error {
    case noCaloriesReported
}
