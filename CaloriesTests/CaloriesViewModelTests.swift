//
//  CaloriesTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import XCTest
@testable import Calories

final class CaloriesViewModelTests: XCTestCase {
    var controller: PersistenceController!
    var container: NSPersistentContainer {
        controller.container
    }
    var context: NSManagedObjectContext {
        container.viewContext
    }

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
    }

    override func tearDownWithError() throws {
        controller = nil
    }

    func testGivenPermissionGrantedCanAddCalories() async throws {
        let subject = await CaloriesViewModel(healthStore: MockHealthStore(), container: container)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!
        try await subject.addFood(foodDescription: "Some food",
                                  calories: 100,
                                  timeConsumed: date)
        try await subject.fetchCaloriesConsumed()
        let caloriesConsumed = await subject.calorieStats.caloriesConsumed
        XCTAssertEqual(caloriesConsumed, 100)

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
        let mockHealthStore = MockHealthStore()
        mockHealthStore.authorizeError = HealthStoreError.ErrorNoHealthDataAvailable
        let subject = await CaloriesViewModel(healthStore: mockHealthStore, container: container)
        do {
            let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
            let date = dc.date!
            try await subject.addFood(foodDescription: "Some food",
                                      calories: 100,
                                      timeConsumed: date)
        } catch {
            // Expected
        }
        try await subject.fetchCaloriesConsumed()
        let caloriesConsumed = await subject.calorieStats.caloriesConsumed
        XCTAssertEqual(caloriesConsumed, 0)
    }

    func testTodaysEntriesReturnedOnly() async throws {
        let subject = await CaloriesViewModel(healthStore: MockHealthStore(), container: container)
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

        await subject.setDateForEntries(Calendar.current.startOfDay(for: lateDate))
        let entries = await subject.foodEntries
        XCTAssertEqual(entries.map { $0.foodDescription }, ["Some more food"])
    }

    func testCanDeleteFoodEntry() async throws {
        let subject = await CaloriesViewModel(healthStore: MockHealthStore(), container: container)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!
        try await subject.addFood(foodDescription: "Some food",
                                  calories: 100,
                                  timeConsumed: date)

        let fetchRequest: NSFetchRequest<FoodEntry> = FoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "foodDescription == %@", "Some food")
        let preResult = try? context.fetch(fetchRequest)
        guard let foodEntry = preResult?.first else {
            XCTFail("Expected food entry")
            return
        }
        await subject.deleteFoodEntry(foodEntry)
        let postResult = try? context.fetch(fetchRequest)
        XCTAssertEqual(postResult?.count, 0)
    }

    func testClearDownOfInProgressDetailsAfterDay() async {
        let result = await CaloriesViewModel.shouldClearFields(phase: .active, date: Date().addingTimeInterval(-86400))
        XCTAssertTrue(result)
    }

    func testNoClearDownOfInProgressDetailsOnSameDay() async {
        let result = await CaloriesViewModel.shouldClearFields(phase: .active, date: Date())
        XCTAssertFalse(result)
    }
}

class MockHealthStore: HealthStore {
    var authorizeError: Error?
    var bmr: Int = 0
    var exercise: Int = 0
    var caloriesConsumed: Int = 0

    func authorize() async throws {
        guard let error = authorizeError else {
            return
        }
        throw error
    }

    func bmr() async throws -> Int {
        bmr
    }

    func exercise() async throws -> Int {
        exercise
    }

    func caloriesConsumed() async throws -> Int {
        caloriesConsumed
    }

    func addFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed += Int(foodEntry.calories)
    }

    func deleteFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed -= Int(foodEntry.calories)
    }
}
