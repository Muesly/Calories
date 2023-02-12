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
        let subject = await AddEntryViewModel(healthStore: MockHealthStore(), container: container)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!
        try await subject.addFood(foodDescription: "Some food",
                                  calories: 100,
                                  timeConsumed: date)
//        try await subject.fetchCaloriesConsumed()
//        let caloriesConsumed = await subject.calorieStats.caloriesConsumed
//        XCTAssertEqual(caloriesConsumed, 100)

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
        let subject = await AddEntryViewModel(healthStore: mockHealthStore, container: container)
        do {
            let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
            let date = dc.date!
            try await subject.addFood(foodDescription: "Some food",
                                      calories: 100,
                                      timeConsumed: date)
        } catch {
            // Expected
        }
//        try await subject.fetchCaloriesConsumed()
//        let caloriesConsumed = await subject.calorieStats.caloriesConsumed
//        XCTAssertEqual(caloriesConsumed, 0)
    }

    func testTodaysEntriesReturnedOnly() async throws {
        let subject = await AddEntryViewModel(healthStore: MockHealthStore(), container: container)
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

    func testClearDownOfInProgressDetailsAfterDay() async {
        let result = await AddEntryViewModel.shouldClearFields(phase: .active, date: Date().addingTimeInterval(-86400))
        XCTAssertTrue(result)
    }

    func testNoClearDownOfInProgressDetailsOnSameDay() async {
        let result = await AddEntryViewModel.shouldClearFields(phase: .active, date: Date())
        XCTAssertFalse(result)
    }

}

