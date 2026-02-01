//
//  AddExerciseViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 20/02/2023.
//

import Foundation
import XCTest

@testable import Calories

@MainActor
final class AddExerciseViewModelTests: XCTestCase {
    var subject: AddExerciseViewModel!
    var mockHealthStore: MockHealthStore!

    override func setUpWithError() throws {
        mockHealthStore = MockHealthStore()
        subject = AddExerciseViewModel(
            healthStore: mockHealthStore,
            modelContext: .inMemory,
            timeExercised: Date())
    }

    override func tearDownWithError() throws {
        subject = nil
        mockHealthStore = nil
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testGivenPermissionGrantedCanAddCalories() async throws {
        try await subject.addExercise(
            exerciseDescription: "Ran somewhere",
            calories: 100,
            timeExercised: dateFromComponents())
        XCTAssertEqual(mockHealthStore.caloriesBurned, 100)
    }

    func testDeniedPermissionGrantedCanAddExerciseEntry() async throws {
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        do {
            try await subject.addExercise(
                exerciseDescription: "Ran somewhere",
                calories: 100,
                timeExercised: dateFromComponents())
        } catch let healthStoreError as HealthStoreError {
            XCTAssertEqual(healthStoreError, HealthStoreError.errorNoHealthDataAvailable)
        }
        XCTAssertEqual(mockHealthStore.caloriesBurned, 0)
    }

    func testClearDownOfInProgressDetailsAfterDay() async {
        let result = AddExerciseViewModel.shouldClearFields(
            phase: .active, date: Date().addingTimeInterval(-secsPerDay))
        XCTAssertTrue(result)
    }

    func testNoClearDownOfInProgressDetailsOnSameDay() async {
        let result = AddExerciseViewModel.shouldClearFields(phase: .active, date: Date())
        XCTAssertFalse(result)
    }
}
