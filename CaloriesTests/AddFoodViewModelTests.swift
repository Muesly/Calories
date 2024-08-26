//
//  AddFoodViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 11/02/2023.
//

import CoreData
import Foundation
import SwiftData
import XCTest

@testable import Calories

final class AddFoodViewModelTests: XCTestCase {
    var subject: AddFoodViewModel!
    var mockHealthStore: MockHealthStore!
    var modelContext: ModelContext!

    @MainActor override func setUpWithError() throws {
        modelContext = ModelContext.inMemory
        mockHealthStore = MockHealthStore()
        subject = AddFoodViewModel(healthStore: mockHealthStore, modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        subject = nil
        mockHealthStore = nil
        modelContext = nil
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testGivenPermissionGrantedCanAddCalories() async throws {
        try await subject.addFood(foodDescription: "Some food",
                                  calories: 100,
                                  timeConsumed: dateFromComponents(),
                                  plants: [])
        guard let foodEntry = modelContext.foodResults(for: #Predicate { $0.foodDescription == "Some food" }).first else {
            XCTFail("Expected food entry")
            return
        }

        XCTAssertEqual(foodEntry.foodDescription, "Some food")
    }

    func testDeniedPermissionGrantedCanAddFoodEntry() async throws {
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        do {
            try await subject.addFood(foodDescription: "Some food",
                                      calories: 100,
                                      timeConsumed: dateFromComponents(),
                                      plants: [])
        } catch let healthStoreError as HealthStoreError {
            XCTAssertEqual(healthStoreError, HealthStoreError.errorNoHealthDataAvailable)
        }
        XCTAssertTrue(modelContext.foodResults(for: #Predicate { $0.foodDescription == "Some food" }).isEmpty)
    }

    func testClearDownOfInProgressDetailsAfterDay() async {
        let result = AddFoodViewModel.shouldClearFields(phase: .active, date: Date().addingTimeInterval(-secsPerDay))
        XCTAssertTrue(result)
    }

    func testNoClearDownOfInProgressDetailsOnSameDay() async {
        let result = AddFoodViewModel.shouldClearFields(phase: .active, date: Date())
        XCTAssertFalse(result)
    }

    func testWhenNoSuggestionsShownForAFoodEntryWhenFoodFromToday() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date,
                                  plants: [])
        subject.fetchSuggestions()
        XCTAssertEqual(subject.suggestions, [])
    }

    func testWhenNoSuggestionsShownForAFoodEntryWhenFoodNotInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-secsPerDay - (3 * 3600)),
                                  plants: [])
        subject.fetchSuggestions()
        XCTAssertEqual(subject.suggestions, [])
    }

    func testWhenSuggestionsShownForAFoodEntryWhenFoodInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-secsPerDay),
                                  plants: [])
        subject.fetchSuggestions()
        XCTAssertEqual(subject.suggestions, [Suggestion(name: "Some more food")])
    }

    func testSuggestionsFuzzyMatched() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-secsPerDay),
                                  plants: [])
        subject.fetchSuggestions(searchText: "more")
        XCTAssertEqual(subject.suggestions, [Suggestion(name: "Some more food")])

        subject.fetchSuggestions(searchText: "mxe")  // Shouldn't return results
        XCTAssertEqual(subject.suggestions, [])
    }

    func testDefaultCaloriesForTwoSimilarFoodEntriesReturnsLatest() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Cornflakes",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-1800),
                                  plants: [])
        try await subject.addFood(foodDescription: "Cornflakes",
                                  calories: 200,
                                  timeConsumed: date.addingTimeInterval(-3600),
                                  plants: [])
        let defCalories = subject.foodTemplateFor("Cornflakes").calories

        XCTAssertEqual(defCalories, 100)
    }

    func testPrompt() {
        let date = dateFromComponents()
        XCTAssertEqual(subject.prompt(for: date), "Enter Morning Snack food or drink...")
    }

    func testCalorieSearchURL() {
        XCTAssertEqual(subject.calorieSearchURL(for: "Banana Cake").absoluteString, "https://www.myfitnesspal.com/nutrition-facts-calories/Banana%20Cake")
    }
}
