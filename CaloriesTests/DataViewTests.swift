//
//  DataViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 05/05/2024.
//

import XCTest

@testable import Calories

final class DataViewTests: XCTestCase {
    var controller: PersistenceController!
    var mockHealthStore: MockHealthStore!
    let segmentLength = 10.0 * 86400
    
    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
        mockHealthStore = MockHealthStore()
    }
    
    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }
    
    func testFailedDataFetchWhenNoConsumptionData() async throws {
        let vm = DataViewModel(healthStore: mockHealthStore)
        do {
            let _ = try await vm.calculate()
            XCTFail("Shouldn't succeed")
        } catch {
            XCTAssertEqual(error as? DataViewError, DataViewError.failedToGetFirstCaloriesConsumedItem)
        }
    }
    
    private var oneAndABitSegments: [(Date, Int)] {
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        let seg2EndDate = seg2StartDate.addingTimeInterval(segmentLength)
        
        let seg1DataPoint1 = (seg1StartDate, 2200)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 2600)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 1900)
        
        let seg2DataPoint1 = (seg2StartDate, 2200)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 2000)
        
        return [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
    }
    
    private var oneAndABitSegmentsForBMR: [(Date, Int)] {
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        let seg2EndDate = seg2StartDate.addingTimeInterval(segmentLength)
        
        let seg1DataPoint1 = (seg1StartDate, 1800)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 1800)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 1800)
        
        let seg2DataPoint1 = (seg2StartDate, 1800)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 1800)
        
        return [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
    }
    
    private var oneAndABitSegmentsForActiveCalories: [(Date, Int)] {
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        let seg2EndDate = seg2StartDate.addingTimeInterval(segmentLength)
        
        let seg1DataPoint1 = (seg1StartDate, 800)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 300)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 600)
        
        let seg2DataPoint1 = (seg2StartDate, 300)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 150)
        
        return [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
    }

    private var oneAndABitSegmentsForWeight: [(Date, Double)] {
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        let seg2EndDate = seg2StartDate.addingTimeInterval(segmentLength)
        
        let seg1DataPoint1 = (seg1StartDate, 14.8)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 14.6)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 14.3)
        
        let seg2DataPoint1 = (seg2StartDate, 14.3)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 14.2)
        
        return [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
    }

    func testDateRangeCuttingOffIncomplete() async throws {
        let dataPoints = oneAndABitSegments
        mockHealthStore.caloriesConsumedAllDataPoints = dataPoints
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()
        XCTAssertEqual(response.segments,
                       [Segment(consumptionDataPoints: [.init(date: dataPoints[0].0,
                                                              calories: dataPoints[0].1),
                                                        .init(date: dataPoints[1].0,
                                                              calories: dataPoints[1].1),
                                                        .init(date: dataPoints[2].0,
                                                              calories: dataPoints[2].1)],
                                bmrTotal: 0,
                                activeTotal: 0,
                                startWeight: 0,
                                endWeight: 0,
                                startDate: dataPoints[0].0,
                                endDate: dataPoints[0].0.addingTimeInterval(segmentLength))])
    }
    
    func testCaloriesConsumedInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()
        
        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.caloriesConsumed, 6700)
    }
    
    func testBMRInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.bmrAllDataPoints = oneAndABitSegmentsForBMR
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()
        
        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.bmrTotal, 5400)
    }
    
    func testActiveCaloriesInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.activeCaloriesAllDataPoints = oneAndABitSegmentsForActiveCalories
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()
        
        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.activeTotal, 1700)
    }
    
    func testWeightInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.weightAllDataPoints = oneAndABitSegmentsForWeight
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()

        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.endWeight, 14.3)
    }
    
    func testExpectedWeightLossPerDeficit() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.bmrAllDataPoints = oneAndABitSegmentsForBMR
        mockHealthStore.activeCaloriesAllDataPoints = oneAndABitSegmentsForActiveCalories
        mockHealthStore.weightAllDataPoints = oneAndABitSegmentsForWeight
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()

        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.expectedWeightLoss, 0.1111111111111111)
        XCTAssertEqual(firstSegment.actualWeightLoss, 0.5)
        XCTAssertEqual(firstSegment.weightVariance, 0.3888888888888889)
    }
}

enum DataViewError: Error {
    case failedToGetCaloriesConsumed
    case failedToGetFirstCaloriesConsumedItem
}

struct CalorieDataPoint: Equatable {
    let date: Date
    let calories: Int
}

struct ReportedWeightDataPoint: Equatable {
    let date: Date
    let weight: Double
}

struct Segment: Equatable {
    let consumptionDataPoints: [CalorieDataPoint]
    let bmrTotal: Int
    let activeTotal: Int
    let startWeight: Double
    let endWeight: Double
    let startDate: Date
    let endDate: Date
    
    var caloriesConsumed: Int { consumptionDataPoints.reduce(0) { $0 + $1.calories } }

    var expectedWeightLoss: Double {
        return Double(bmrTotal + activeTotal - caloriesConsumed) / 3600
    }
    
    var actualWeightLoss: Double {
        return startWeight - endWeight
    }
    
    var weightVariance: Double {
        return abs(expectedWeightLoss - actualWeightLoss)
    }
}

struct CalculatedData: Equatable {
    let segments: [Segment]
    var startDate: Date? { segments.first?.startDate }
    var endDate: Date? {segments.last?.endDate }
}

class DataViewModel {
    let healthStore: HealthStore
    
    init(healthStore: HealthStore) {
        self.healthStore = healthStore
    }
    
    private func getConsumptionDataPoints() async throws -> [CalorieDataPoint] {
        let currentDate = Date()
        let fromDateComponents = NSDateComponents()
        fromDateComponents.year = 2023
        fromDateComponents.month = 1
        fromDateComponents.day = 1
        let fromDate = Calendar.current.date(from: fromDateComponents as DateComponents)!
        let consumptionDataPoints: [CalorieDataPoint]
        do {
            consumptionDataPoints = try await healthStore.caloriesConsumedAllDataPoints(fromDate: fromDate, toDate: currentDate).map {
                .init(date: $0.0, calories: $0.1)
            }
        } catch {
            throw DataViewError.failedToGetCaloriesConsumed
        }
        return consumptionDataPoints
    }

    private func createSegment(consumptionDataPoints: [CalorieDataPoint],
                               bmrDataPoints: [CalorieDataPoint],
                               activeDataPoints: [CalorieDataPoint],
                               startWeight: Double,
                               weightDataPoints: [ReportedWeightDataPoint],
                               startDate: Date,
                               endDate: Date) -> Segment {
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

        let lastWeightInDataPoints = weightDataPoints.last(where: { $0.date >= startDate && $0.date < endDate })?.weight ?? 0

        return Segment(consumptionDataPoints: consumptionDataPoints,
                       bmrTotal: bmrTotal,
                       activeTotal: activeTotal,
                       startWeight: startWeight,
                       endWeight: lastWeightInDataPoints,
                       startDate: startDate,
                       endDate: endDate)
    }
    
    private func createSegments(firstRecordedDate: Date,
                                consumptionDataPoints: [CalorieDataPoint],
                                bmrDataPoints: [CalorieDataPoint],
                                activeDataPoints: [CalorieDataPoint],
                                weightDataPoints: [ReportedWeightDataPoint]) -> [Segment] {
        var segments = [Segment]()
        let segmentLength = 10.0 * 86400
        var nextSegmentDate = firstRecordedDate + segmentLength
        var currentDataPoints = [CalorieDataPoint]()
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
                startWeight = weightDataPoints.last?.weight ?? 0
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
                                                                  toDate: lastRecordedDate).map {
            CalorieDataPoint(date: $0.0, calories: $0.1)
        }

        let activeDataPoints = try await healthStore.activeBetweenDates(fromDate: firstRecordedDate,
                                                                     toDate: lastRecordedDate).map {
            CalorieDataPoint(date: $0.0, calories: $0.1)
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
}
