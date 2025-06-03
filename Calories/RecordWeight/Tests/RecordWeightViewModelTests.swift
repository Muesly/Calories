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
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testGivenPermissionGrantedCanReadWeight() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.weight = 194
        mockHealthStore.caloriesConsumed = 2500
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 900
        let date = dateFromComponents()
        mockHealthStore.weightAllDataPoints = [
            (date.startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
            (date.startOfWeek.addingTimeInterval(-1), 190),
            (date, 180),
        ]

        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        try await subject.fetchWeightData(date: date, numWeeks: 3)
        XCTAssertEqual(
            subject.weightData,
            [
                WeightDataPoint(
                    date: date.startOfWeek.addingTimeInterval(-(7 * 86400) - 1), weight: 200,
                    deficit: -2100),
                WeightDataPoint(
                    date: date.startOfWeek.addingTimeInterval(-1), weight: 190, deficit: -2100),
                WeightDataPoint(date: date, weight: 180, deficit: -2100),
            ])
    }

    func testNoPermissionGrantedCannotReadWeight() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        let date = dateFromComponents()
        do {
            try await subject.fetchWeightData(date: date)
            XCTFail("Expects to fail")
        } catch {
        }
    }

    func testWeekStr() {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        let weightDataPoint = WeightDataPoint(date: dateFromComponents(), weight: 192, deficit: 0)
        let weightDataPoint2 = WeightDataPoint(
            date: dateFromComponents().addingTimeInterval(20 * secsPerDay), weight: 188, deficit: 0)
        subject.weightData = [weightDataPoint, weightDataPoint2]
        XCTAssertEqual(subject.weekStr(forDataPoint: weightDataPoint2), "16 Jan 23")
    }

    func testProgressShownInStonesAndPounds() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.caloriesConsumed = 2000
        mockHealthStore.caloriesBurned = 2200
        let date = dateFromComponents()
        mockHealthStore.weightAllDataPoints = [
            (date.startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
            (date.startOfWeek.addingTimeInterval(-1), 190),
            (date, 180),
        ]
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        try await subject.fetchWeightData(date: date, numWeeks: 3)

        XCTAssertEqual(subject.totalLoss, "Progress: 1 stone 6 lbs \u{2193}")
    }

    func testWeightChange() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.caloriesConsumed = 2000
        mockHealthStore.caloriesBurned = 2200
        let date = dateFromComponents()
        mockHealthStore.weightAllDataPoints = [
            (date.addingTimeInterval(-21 * 86400), 200),
            (date.addingTimeInterval(-14 * 86400), 190),
            (date.addingTimeInterval(-7 * 86400), 180),
        ]
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)

        try await subject.fetchWeightData(date: date.addingTimeInterval(-7 * 86400), numWeeks: 7)
        XCTAssertEqual(subject.totalLoss, "Progress: 1 stone 6 lbs \u{2193}")

        subject.latestWeight -= 1
        try await subject.applyNewWeight(date: date)
        mockHealthStore.weightBetweenDatesIndex = 0
        try await subject.fetchWeightData(date: date, numWeeks: 7)

        XCTAssertEqual(subject.totalLoss, "Progress: 1 stone 7 lbs \u{2193}")
    }

    func testWeightStringFormatting() {
        let mockHealthStore = MockHealthStore()
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)

        XCTAssertEqual(subject.weightStr(196), "14st 0")
        XCTAssertEqual(subject.weightStr(197), "14st 1")
        XCTAssertEqual(subject.weightStr(210), "15st 0")
    }

    func testWeightIncreaseDecrease() {
        let mockHealthStore = MockHealthStore()
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        subject.latestWeight = 196

        subject.increaseWeight()
        XCTAssertEqual(subject.latestWeight, 197)

        subject.decreaseWeight()
        XCTAssertEqual(subject.latestWeight, 196)
    }

    func testNoCaloriesReported() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.caloriesConsumed = 0  // This will trigger noCaloriesReported error
        let date = dateFromComponents()
        mockHealthStore.weightAllDataPoints = [
            (date.startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
            (date.startOfWeek.addingTimeInterval(-1), 190),
            (date, 180),
        ]

        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        try await subject.fetchWeightData(date: date, numWeeks: 3)

        // Should still have weight data but with 0 deficit
        XCTAssertEqual(subject.weightData.count, 1)
        XCTAssertEqual(subject.weightData[0].deficit, 0)
        XCTAssertEqual(subject.weightData[0].weight, 180)
    }
}
