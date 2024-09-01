//
//  DataViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 05/05/2024.
//

import XCTest

@testable import Calories

final class DataViewTests: XCTestCase {
    var mockHealthStore: MockHealthStore!
    let segmentLength = 10.0 * 86400
    
    override func setUpWithError() throws {
        mockHealthStore = MockHealthStore()
    }
    
    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }
    
    private func setupVM() -> DataViewModel {
        DataViewModel(healthStore: mockHealthStore, segmentLengthInDays: 10)
    }
    
    func testFailedDataFetchWhenNoConsumptionData() async throws {
        let vm = setupVM()
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
        
        let seg1DataPoint1 = (seg1StartDate, 800)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 300)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 600)
        
        let seg2DataPoint1 = (seg2StartDate, 300)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 150)
        
        return [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
    }

    private var oneAndABitSegmentsForWeight: [(Date, Int)] {
        let seg1StartDate = Date()
        let seg1EndDate = seg1StartDate.addingTimeInterval(segmentLength)
        let seg2StartDate = seg1EndDate
        
        let seg1DataPoint1 = (seg1StartDate, 202)
        let seg1DataPoint2 = (seg1StartDate.addingTimeInterval(86400), 200)
        let seg1DataPoint3 = (seg1StartDate.addingTimeInterval(2 * 86400), 197)

        let seg2DataPoint1 = (seg2StartDate, 197)
        let seg2DataPoint2 = (seg2StartDate.addingTimeInterval(86400), 196)

        return [seg1DataPoint1, seg1DataPoint2, seg1DataPoint3, seg2DataPoint1, seg2DataPoint2]
    }

    func testDateRangeCuttingOffIncomplete() async throws {
        let dataPoints = oneAndABitSegments
        mockHealthStore.caloriesConsumedAllDataPoints = dataPoints
        let vm = setupVM()
        let response = try! await vm.calculate()
        XCTAssertEqual(response.segments,
                       [Segment(caloriesConsumed: 6700,
                                bmrTotal: 0,
                                activeTotal: 0,
                                startWeight: 0,
                                endWeight: 0,
                                startDate: dataPoints[0].0,
                                endDate: dataPoints[0].0.addingTimeInterval(segmentLength))])
    }
    
    func testCaloriesConsumedInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        let vm = setupVM()
        let response = try! await vm.calculate()
        
        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.caloriesConsumed, 6700)
    }
    
    func testBMRInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.bmrAllDataPoints = oneAndABitSegmentsForBMR
        let vm = setupVM()
        let response = try! await vm.calculate()
        
        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.bmrTotal, 5400)
    }
    
    func testActiveCaloriesInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.activeCaloriesAllDataPoints = oneAndABitSegmentsForActiveCalories
        let vm = setupVM()
        let response = try! await vm.calculate()
        
        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.activeTotal, 1700)
    }
    
    func testWeightInSegment() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.weightAllDataPoints = oneAndABitSegmentsForWeight
        let vm = setupVM()
        let response = try! await vm.calculate()

        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.endWeight, 197)
    }
    
    func testExpectedWeightLossPerDeficit() async throws {
        mockHealthStore.caloriesConsumedAllDataPoints = oneAndABitSegments
        mockHealthStore.bmrAllDataPoints = oneAndABitSegmentsForBMR
        mockHealthStore.activeCaloriesAllDataPoints = oneAndABitSegmentsForActiveCalories
        mockHealthStore.weightAllDataPoints = oneAndABitSegmentsForWeight
        let vm = setupVM()
        let response = try! await vm.calculate()

        let firstSegment = response.segments.first!
        XCTAssertEqual(firstSegment.expectedWeightLoss, 0.11428571428571428)
        XCTAssertEqual(firstSegment.actualWeightLoss, 5)
        XCTAssertEqual(firstSegment.weightVariance, -4.885714285714286)
    }
}
