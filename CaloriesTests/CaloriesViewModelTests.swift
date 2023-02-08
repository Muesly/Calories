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
        let total = try await subject.totalCaloriesConsumed()
        XCTAssertEqual(total, 100)

        let fetchRequest: NSFetchRequest<FoodEntry> = FoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "foodDescription == %@", "Some food")
        let result = try? context.fetch(fetchRequest)

        guard let foodEntry = result?.first else {
            XCTFail("Expected food entry")
            return
        }

        XCTAssertEqual(foodEntry.foodDescription, "Some food")
    }

    func testDeniedPermissionGrantedCanAddCalories() async throws {
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
        let total = try await subject.totalCaloriesConsumed()
        XCTAssertEqual(total, 0)
    }
}

class MockHealthStore: HealthStore {
    var authorizeError: Error?
    var caloriesConsumed: Double = 0

    func authorize() async throws {
        guard let error = authorizeError else {
            return
        }
        throw error
    }

    func totalCaloriesConsumed() async throws -> Double {
        return caloriesConsumed
    }

    func writeFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed += foodEntry.calories
    }
}
