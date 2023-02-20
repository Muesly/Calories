//
//  RecordWeightViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 20/02/2023.
//

import Foundation
import XCTest

@testable import Calories

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
        mockHealthStore.weight = 14.5
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        let date = dateFromComponents()
        try await subject.fetchWeightData(date: date)
        XCTAssertEqual(subject.weightData, [WeightDataPoint(date: date, weight: 14.5)])
    }

    func testNoPermissionGrantedCannotReadWeight() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.authorizeError = HealthStoreError.ErrorNoHealthDataAvailable
        let subject = RecordWeightViewModel(healthStore: mockHealthStore)
        do {
            try await subject.fetchWeightData()
            XCTFail("Expects to fail")
        } catch {
        }
    }
}

