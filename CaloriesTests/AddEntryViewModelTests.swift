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
    var calorieStats: CalorieStats!

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
        calorieStats = CalorieStats(healthStore: mockHealthStore, dispatchQueue: MockDispatcher())
        subject = AddEntryViewModel(healthStore: mockHealthStore,
                                        container: container,
                                        calorieStats: calorieStats)
    }

    override func tearDownWithError() throws {
        subject = nil
        mockHealthStore = nil
        calorieStats = nil
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
        XCTAssertEqual(calorieStats.caloriesConsumed, 100)

        let fetchRequest: NSFetchRequest<FoodEntry> = FoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "foodDescription == %@", "Some food")
        let result = try? context.fetch(fetchRequest)

        guard let foodEntry = result?.first else {
            XCTFail("Expected food entry")
            return
        }

        XCTAssertEqual(foodEntry.foodDescription, "Some food")
    }

    func testDeniedPermissionGrantedCanAddFoodEntry() async throws {
        mockHealthStore.authorizeError = HealthStoreError.ErrorNoHealthDataAvailable
        do {
            try await subject.addFood(foodDescription: "Some food",
                                      calories: 100,
                                      timeConsumed: dateFromComponents())
        } catch let healthStoreError as HealthStoreError {
            XCTAssertEqual(healthStoreError, HealthStoreError.ErrorNoHealthDataAvailable)
        }
        XCTAssertEqual(calorieStats.caloriesConsumed, 0)
    }

    func testTodaysEntriesReturnedOnly() async throws {
        var dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let earlyDate = dc.date!
        try await subject.addFood(foodDescription: "Some food",
                                  calories: 100,
                                  timeConsumed: earlyDate)
        dc.day = 2
        let lateDate = dc.date!
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: lateDate)

        subject.setDateForEntries(Calendar.current.startOfDay(for: lateDate))
        let entries = subject.foodEntries
        XCTAssertEqual(entries.map { $0.foodDescription }, ["Some more food"])
    }

    func testClearDownOfInProgressDetailsAfterDay() async {
        let result = AddEntryViewModel.shouldClearFields(phase: .active, date: Date().addingTimeInterval(-86400))
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
        let suggestions = subject.getSuggestions(currentDate: date)
        XCTAssertEqual(suggestions, [])
    }

    func testWhenNoSuggestionsShownForAFoodEntryWhenFoodNotInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-86400 - (3 * 3600)))
        let suggestions = subject.getSuggestions(currentDate: date)
        XCTAssertEqual(suggestions, [])
    }

    func testWhenSuggestionsShownForAFoodEntryWhenFoodInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(foodDescription: "Some more food",
                                  calories: 100,
                                  timeConsumed: date.addingTimeInterval(-86400))
        let suggestions = subject.getSuggestions(currentDate: date)
        XCTAssertEqual(suggestions, [Suggestion(name: "Some more food")])
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
}

class MockDispatcher: Dispatching {
    func async(execute work: @escaping @convention(block) () -> Void) {
        work()
    }
}
