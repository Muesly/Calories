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

    func testCanDeleteFoodEntry() async throws {
        let subject = CaloriesViewModel(healthStore: MockHealthStore(), container: container)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!

        _ = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: date)
        try container.viewContext.save()

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

    func testFetchingFoodEntriesSortsMostRecentFirst() async throws {
        let subject = CaloriesViewModel(healthStore: MockHealthStore(), container: container)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!
        subject.dateForEntries = date
        let entry1 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: date)
        let entry2 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some more food",
                                  calories: Double(200),
                                  timeConsumed: date.addingTimeInterval(600))
        try container.viewContext.save()

        let foodEntries = subject.foodEntries
        XCTAssertEqual(foodEntries, [entry2, entry1])
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

    func bmr(date: Date?) async throws -> Int {
        bmr
    }

    func exercise(date: Date?) async throws -> Int {
        exercise
    }

    func caloriesConsumed(date: Date?) async throws -> Int {
        caloriesConsumed
    }

    func addFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed += Int(foodEntry.calories)
    }

    func deleteFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed -= Int(foodEntry.calories)
    }
}
