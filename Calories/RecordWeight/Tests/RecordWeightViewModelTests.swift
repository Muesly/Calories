//
//  RecordWeightViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 20/02/2023.
//

import Foundation
import XCTest

@testable import Calories

@MainActor
final class RecordWeightViewModelTests: XCTestCase {
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testGivenPermissionGrantedCanReadWeight() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.weight = 194
        mockHealthStore.caloriesConsumed = 2500
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 900

        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        let date = dateFromComponents()
        try await subject.fetchWeightData(date: date, numWeeks: 3)
        XCTAssertEqual(subject.weightData, [WeightDataPoint(date: date.startOfWeek.addingTimeInterval(-(7 * 86400) - 1), weight: 194, deficit: -2100),
                                            WeightDataPoint(date: date.startOfWeek.addingTimeInterval(-1), weight: 194, deficit: -2100),
                                            WeightDataPoint(date: date, weight: 194, deficit: -2100)])
    }

    func testNoPermissionGrantedCannotReadWeight() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        do {
            try await subject.fetchWeightData()
            XCTFail("Expects to fail")
        } catch {
        }
    }

    func testWeekStr() {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        let weightDataPoint = WeightDataPoint(date: dateFromComponents(), weight: 192, deficit: 0)
        let weightDataPoint2 = WeightDataPoint(date: dateFromComponents().addingTimeInterval(20 * secsPerDay), weight: 188, deficit: 0)
        subject.weightData = [weightDataPoint, weightDataPoint2]
        XCTAssertEqual(subject.weekStr(forDataPoint: weightDataPoint2), "16 Jan 23")
    }
    
    func testProgressShownInStonesAndPounds() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.caloriesConsumed = 2000
        mockHealthStore.caloriesBurned = 2200
        mockHealthStore.weightBetweenDates = [200, 190, 180]
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)

        let date = dateFromComponents()
        try await subject.fetchWeightData(date: date, numWeeks: 3)

        XCTAssertEqual(subject.totalLoss, "Progress: 1 stone 6 lbs \u{2193}")
    }
}

