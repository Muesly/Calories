//
//  HistoryViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftData
import XCTest

@testable import Calories

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var subject: HistoryViewModel!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        modelContext = .inMemory
        subject = HistoryViewModel(healthStore: MockHealthStore())
        subject.modelContext = modelContext
    }

    override func tearDownWithError() throws {
        modelContext = nil
        subject = nil
    }

    private var dateFromComponents: Date {
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testCanDeleteFoodEntry() async throws {
        let _ = FoodEntry(
            foodDescription: "Some food",
            calories: Double(100),
            timeConsumed: dateFromComponents
        ).insert(into: modelContext)
        let predicate: Predicate<FoodEntry> = #Predicate { $0.foodDescription == "Some food" }
        let preResult = modelContext.foodResults(for: predicate)
        guard let foodEntry = preResult.first else {
            XCTFail("Expected food entry")
            return
        }
        await subject.deleteFoodEntry(foodEntry)
        let postResult = modelContext.foodResults(for: predicate)
        XCTAssertTrue(postResult.isEmpty)
    }

    func testFetchingFoodEntriesSortsMostRecentFirst() async throws {
        let entry1 = FoodEntry(
            foodDescription: "Some food",
            calories: Double(100),
            timeConsumed: dateFromComponents
        ).insert(into: modelContext)
        let entry2 = FoodEntry(
            foodDescription: "Some more food",
            calories: Double(200),
            timeConsumed: dateFromComponents.addingTimeInterval(600)
        ).insert(into: modelContext)

        let foodEntries = subject.foodEntries(forDate: dateFromComponents)
        XCTAssertEqual(foodEntries, [entry2, entry1])
    }

    func testFetchingDaySections() async throws {
        let date = dateFromComponents
        let entry1 = FoodEntry(
            foodDescription: "Some food",
            calories: Double(100),
            timeConsumed: date
        ).insert(into: modelContext)
        let entry2 = FoodEntry(
            foodDescription: "Some more food",
            calories: Double(200),
            timeConsumed: date.addingTimeInterval(90600)
        ).insert(into: modelContext)
        let entry3 = FoodEntry(
            foodDescription: "Even more food",
            calories: Double(100),
            timeConsumed: date.addingTimeInterval(90700)
        ).insert(into: modelContext)
        let entry4 = FoodEntry(
            foodDescription: "Late addition",
            calories: Double(50),
            timeConsumed: date.addingTimeInterval(112700)
        ).insert(into: modelContext)

        subject.fetchDaySections(forDate: dateFromComponents)
        let expectedDay1 = Day(
            date: Calendar.current.startOfDay(for: date.addingTimeInterval(secsPerDay)))
        expectedDay1.meals.append(Meal(mealType: .dinner, foodEntries: [entry4]))
        expectedDay1.meals.append(Meal(mealType: .lunch, foodEntries: [entry3, entry2]))
        let expectedDay2 = Day(date: Calendar.current.startOfDay(for: date))
        expectedDay2.meals.append(Meal(mealType: .morningSnack, foodEntries: [entry1]))

        XCTAssertEqual(subject.daySections, [expectedDay1, expectedDay2])
    }

    func testGettingDayTitleAndMealSummaryInHistoryView() async throws {
        _ = FoodEntry(
            foodDescription: "Some food",
            calories: Double(100),
            timeConsumed: dateFromComponents
        ).insert(into: modelContext)
        subject.fetchDaySections(forDate: dateFromComponents)
        XCTAssertEqual(subject.daySections.first?.title, "Sunday, Jan 1")
        XCTAssertEqual(subject.daySections.first?.meals.first?.summary, "Morning Snack (100 cals)")
    }

    func testMovingFoodEntryBetweenMeals() async throws {
        // Create an entry in Evening Snack (21:00)
        let eveningTime = Calendar.current.date(
            bySettingHour: 21, minute: 0, second: 0, of: dateFromComponents)!
        let foodEntry = FoodEntry(
            foodDescription: "Dessert",
            calories: Double(200),
            timeConsumed: eveningTime
        ).insert(into: modelContext)

        // Move it to Dinner (18:00)
        let dinnerTime = Calendar.current.date(
            bySettingHour: 18, minute: 0, second: 0, of: dateFromComponents)!
        await subject.moveFoodEntry(foodEntry, to: dinnerTime)

        // Verify the entry is now in Dinner
        subject.fetchDaySections(forDate: dateFromComponents)
        let dinnerMeal = subject.daySections.first?.meals.first { $0.mealType == .dinner }
        XCTAssertEqual(dinnerMeal?.foodEntries.count, 1)
        XCTAssertEqual(dinnerMeal?.foodEntries.first?.foodDescription, "Dessert")
        XCTAssertEqual(dinnerMeal?.foodEntries.first?.calories, 200)
    }
}
