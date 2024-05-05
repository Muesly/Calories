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
    
    func testDatesOfFirstConsumptionDataPoints() async throws {
        let date1 = Date()
        let date2 = date1.addingTimeInterval(7 * 86400)
        let dataPoint1 = (date1, 2200.0)
        let dataPoint2 = (date2, 2300.0)
        let consumptionDataPoints = [dataPoint1, dataPoint2]
        mockHealthStore.caloriesConsumedAllDataPoints = consumptionDataPoints
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()
        XCTAssertEqual(response.startDate, date1)
        XCTAssertEqual(response.endDate, date2)
    }
    
    func testDateRangeCuttingOffIncomplete() async throws {
        let segmentLength = 10.0 * 86400
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        let seg2EndDate = seg2StartDate.addingTimeInterval(segmentLength)
        
        let seg1DataPoint1 = (seg1StartDate, 2200.0)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 2600.0)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 1900.0)
        
        let seg2DataPoint1 = (seg2EndDate, 2200.0)
        let seg2DataPoint2 = (seg2EndDate.addingTimeInterval(86400), 2000.0)
        
        let consumptionDataPoints = [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
        mockHealthStore.caloriesConsumedAllDataPoints = consumptionDataPoints
        
        let vm = DataViewModel(healthStore: mockHealthStore)
        let response = try! await vm.calculate()
        XCTAssertEqual(response.segments,
                       [Segment(consumptionDataPoints: [.init(date: seg1DataPoint1.0,
                                                              calories: seg1DataPoint1.1),
                                                        .init(date: seg1DataPoint2.0,
                                                              calories: seg1DataPoint2.1),
                                                        .init(date: seg1DataPoint3.0,
                                                              calories: seg1DataPoint3.1)],
                                startDate: seg1StartDate,
                                endDate: seg1StartDate.addingTimeInterval(segmentLength))])
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
    let startDate: Date
    let endDate: Date
}

struct CalculatedData: Equatable {
    let consumptionDataPoints: [ConsumptionDataPoint]
    let segments: [Segment]
    
    var startDate: Date? { consumptionDataPoints.first?.date }
    var endDate: Date? { consumptionDataPoints.last?.date }
}

class DataViewModel {
    let healthStore: HealthStore
    
    init(healthStore: HealthStore) {
        self.healthStore = healthStore
    }
    
    func calculate() async throws -> CalculatedData {
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
        
        guard let firstRecordedDate = consumptionDataPoints.first?.date else {
            throw DataViewError.failedToGetFirstCaloriesConsumedItem
        }
        
        var segments = [Segment]()
        let segmentLength = 10.0 * 86400
        var nextSegmentDate = firstRecordedDate + segmentLength
        var currentDataPoints = [ConsumptionDataPoint]()
        consumptionDataPoints.forEach { dataPoint in
            if dataPoint.date >= nextSegmentDate.addingTimeInterval(segmentLength) {
                segments.append(Segment(consumptionDataPoints: currentDataPoints,
                                        startDate: nextSegmentDate - segmentLength, endDate: nextSegmentDate))
                nextSegmentDate += segmentLength
                currentDataPoints.removeAll()
            }
            currentDataPoints.append(dataPoint)
        }
        let calculatedData = CalculatedData(consumptionDataPoints: consumptionDataPoints,
                                            segments: segments)
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
