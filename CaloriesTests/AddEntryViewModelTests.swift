//
//  AddEntryViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 11/02/2023.
//

import CoreData
import Foundation
import XCTest

@testable import Calories

final class AddEntryViewModelTests: XCTestCase {
    var subject: AddEntryViewModel!
    var mockHealthStore: MockHealthStore!

    var controller: PersistenceController!
    var container: NSPersistentContainer {
        controller.container
    }
    var context: NSManagedObjectContext {
        container.viewContext
    }

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
        mockHealthStore = MockHealthStore()
        subject = AddEntryViewModel(healthStore: mockHealthStore,
                                        container: container)
    }

    override func tearDownWithError() throws {
        subject = nil
        mockHealthStore = nil
        controller = nil
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testGivenPermissionGrantedCanAddCalories() async throws {
        try await subject.addFood(foodDescription: "Some food",
                                  calories: 100,
                                  timeConsumed: dateFromComponents())

        let fetchRequest: NSFetchRequest<FoodEntry> = FoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "foodDescription == %@", "Some food")
        let results = try? context.fetch(fetchRequest)

        guard let foodEntry = results?.first else {
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
                                      timeConsumed: dateFromComponents())
        } catch let healthStoreError as HealthStoreError {
            XCTAssertEqual(healthStoreError, HealthStoreError.errorNoHealthDataAvailable)
        }

        let fetchRequest: NSFetchRequest<FoodEntry> = FoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "foodDescription == %@", "Some food")
        let results = try? context.fetch(fetchRequest)
        XCTAssertEqual(results, [])
    }

    func testClearDownOfInProgressDetailsAfterDay() async {
        let result = AddEntryViewModel.shouldClearFields(phase: .active, date: Date().addingTimeInterval(-secsPerDay))
        XCTAssertTrue(result)
    }

    func testNoClearDownOfInProgressDetailsOnSameDay() async {
        let result = AddEntryViewModel.shouldClearFields(phase: .active, date: Date())
        XCTAssertFalse(result)
    }

    func testWhenNoSuggestionsShownForAFoodEntryWhenFoodFromToday() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date)
        subject.fetchSuggestions()
        XCTAssertEqual(subject.suggestions, [])
    }

    func testWhenNoSuggestionsShownForAFoodEntryWhenFoodNotInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-secsPerDay - (3 * 3600)))
        subject.fetchSuggestions()
        XCTAssertEqual(subject.suggestions, [])
    }

    func testWhenSuggestionsShownForAFoodEntryWhenFoodInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-secsPerDay))
        subject.fetchSuggestions()
        XCTAssertEqual(subject.suggestions, [Suggestion(name: "Some more food")])
    }

    func testSuggestionsFuzzyMatched() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-secsPerDay))
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
                                  timeConsumed: date.addingTimeInterval(-1800))
        try await subject.addFood(foodDescription: "Cornflakes",
                                  calories: 200,
                                  timeConsumed: date.addingTimeInterval(-3600))
        let defCalories = subject.defCaloriesFor("Cornflakes")

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
