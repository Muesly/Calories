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
            let response = try await vm.calculate()
            XCTFail("Shouldn't succeed")
        } catch {
            XCTAssertEqual(error as? DataViewError, DataViewError.failedToGetFirstCaloriesConsumedItem)
        }
    }
    
    private var oneAndABitSegments: [(Date, Double)] {
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        let seg2EndDate = seg2StartDate.addingTimeInterval(segmentLength)
        
        let seg1DataPoint1 = (seg1StartDate, 2200.0)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 2600.0)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 1900.0)
        
        let seg2DataPoint1 = (seg2StartDate, 2200.0)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 2000.0)
        
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
        mockHealthStore.bmr = 2000
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()

        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.bmr, 6700)
    }
}

enum DataViewError: Error {
    case failedToGetCaloriesConsumed
    case failedToGetFirstCaloriesConsumedItem
}

struct ConsumptionDataPoint: Equatable {
    let date: Date
    let calories: Double
}

struct Segment: Equatable {
    let consumptionDataPoints: [ConsumptionDataPoint]
    let bmrDataPoints = [Double]()
    let startDate: Date
    let endDate: Date
    
    var caloriesConsumed: Double { consumptionDataPoints.reduce(0) { $0 + $1.calories } }
    var bmr: Double { bmrDataPoints.reduce(0) { $0 + $1 } }
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
    
    private func getConsumptionDataPoints() async throws -> [ConsumptionDataPoint] {
        let currentDate = Date()
        let fromDateComponents = NSDateComponents()
        fromDateComponents.year = 2023
        fromDateComponents.month = 1
        fromDateComponents.day = 1
        let fromDate = Calendar.current.date(from: fromDateComponents as DateComponents)!
        let consumptionDataPoints: [ConsumptionDataPoint]
        do {
            consumptionDataPoints = try await healthStore.caloriesConsumedAllDataPoints(fromDate: fromDate, toDate: currentDate).map {
                .init(date: $0.0, calories: $0.1)
            }
        } catch {
            throw DataViewError.failedToGetCaloriesConsumed
        }
        return consumptionDataPoints
    }

    private func createSegment(consumptionDataPoints: [ConsumptionDataPoint],
                               startDate: Date,
                               endDate: Date) -> Segment {
        
        return Segment(consumptionDataPoints: consumptionDataPoints,
                       startDate: startDate,
                       endDate: endDate)
    }
    
    private func createSegments(firstRecordedDate: Date,
                                consumptionDataPoints: [ConsumptionDataPoint]) -> [Segment] {
        var segments = [Segment]()
        let segmentLength = 10.0 * 86400
        var nextSegmentDate = firstRecordedDate + segmentLength
        var currentDataPoints = [ConsumptionDataPoint]()
        consumptionDataPoints.forEach { dataPoint in
            if dataPoint.date >= nextSegmentDate {
                let segment = createSegment(consumptionDataPoints: currentDataPoints,
                                            startDate: nextSegmentDate - segmentLength,
                                            endDate: nextSegmentDate)
                segments.append(segment)
                nextSegmentDate += segmentLength
                currentDataPoints.removeAll()
            }
            currentDataPoints.append(dataPoint)
        }
        return segments
    }
    
    func calculate() async throws -> CalculatedData {
        let consumptionDataPoints = try await getConsumptionDataPoints()
        guard let firstRecordedDate = consumptionDataPoints.first?.date else {
            throw DataViewError.failedToGetFirstCaloriesConsumedItem
        }
        let segments = createSegments(firstRecordedDate: firstRecordedDate,
                                      consumptionDataPoints: consumptionDataPoints)
        
        let calculatedData = CalculatedData(segments: segments)
        return calculatedData
        
        //        let df = DateFormatter()
        //        df.dateStyle = .short
        //        let fromDateStr = df.string(from: firstRecordedDate)
        //        let toDateStr = df.string(from: currentDate)
        //        dataText += "Calculating from \(fromDateStr) to \(toDateStr)\n"
        //
        //        guard let numberOfDays = Calendar.current.dateComponents([.day], from: firstRecordedDate, to: currentDate).day else {
        //            return
        //        }
        //        dataText += "\(numberOfDays) days\n"
        //
        //        let segmentLength = Int((Float(numberOfDays) / 10))
        //        var segmentFromDate = firstRecordedDate
        //        var segments = [Segment]()
        //        while segmentFromDate < currentDate {
        //            let segment = Segment(fromDate: segmentFromDate, toDate: segmentFromDate.addingTimeInterval(TimeInterval(segmentLength * 86400)))
        //            segmentFromDate = segment.toDate
        //            segments.append(segment)
        //        }
        //
        //        for (i, segment) in segments.enumerated() {
        //            dataText += "Segment \(i + 1): \(df.string(from: segment.fromDate))\n"
        //        }
    }
}
