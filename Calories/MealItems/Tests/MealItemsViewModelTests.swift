//
//  MealItemsViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 11/02/2023.
//

import SwiftData
import XCTest
@testable import Calories

final class MealItemsViewModelTests: XCTestCase {
    var modelContext: ModelContext!

    @MainActor override func setUpWithError() throws {
        modelContext = .inMemory
    }

    override func tearDownWithError() throws {
        modelContext = nil
    }

    func testMealTitlesDependingOnTimeOfDay() async throws {
        var dc = DateComponents(calendar: Calendar.current)
        dc.hour = 8
        let breakfastSubject = MealItemsViewModel(modelContext: modelContext, currentDate: dc.date!)
        breakfastSubject.fetchMealFoodEntries()
        XCTAssertEqual(breakfastSubject.mealTitle, "Breakfast - 0 Calories")

        dc.hour = 10
        let morningSnackSubject = MealItemsViewModel(modelContext: modelContext, currentDate: dc.date!)
        morningSnackSubject.fetchMealFoodEntries()
        XCTAssertEqual(morningSnackSubject.mealTitle, "Morning Snack - 0 Calories")

        dc.hour = 12
        let lunchSubject = MealItemsViewModel(modelContext: modelContext, currentDate: dc.date!)
        lunchSubject.fetchMealFoodEntries()
        XCTAssertEqual(lunchSubject.mealTitle, "Lunch - 0 Calories")

        dc.hour = 14
        let afternoonSnackSubject = MealItemsViewModel(modelContext: modelContext, currentDate: dc.date!)
        afternoonSnackSubject.fetchMealFoodEntries()
        XCTAssertEqual(afternoonSnackSubject.mealTitle, "Afternoon Snack - 0 Calories")

        dc.hour = 17
        let dinnerSubject = MealItemsViewModel(modelContext: modelContext, currentDate: dc.date!)
        dinnerSubject.fetchMealFoodEntries()
        XCTAssertEqual(dinnerSubject.mealTitle, "Dinner - 0 Calories")

        dc.hour = 20
        let eveningSnackSubject = MealItemsViewModel(modelContext: modelContext, currentDate: dc.date!)
        eveningSnackSubject.fetchMealFoodEntries()
        XCTAssertEqual(eveningSnackSubject.mealTitle, "Evening Snack - 0 Calories")
    }

    func testMealTitlesWithCalories() throws {
        let date = DateComponents(calendar: Calendar.current,
                                  year: 2023,
                                  month: 1,
                                  day: 1,
                                  hour: 8).date!

        let oldEntry = FoodEntry(foodDescription: "Some old food entry",
                          calories: Double(100),
                          timeConsumed: date.addingTimeInterval(-secsPerDay))
        let foodEntry = FoodEntry(foodDescription: "Some food",
                                  calories: Double(200),
                                  timeConsumed: date)
        let secondFoodEntry = FoodEntry(foodDescription: "Some more food",
                                        calories: Double(100),
                                        timeConsumed: date.addingTimeInterval(7199))    // Right at end of breakfast time
        modelContext.insert(oldEntry)
        modelContext.insert(foodEntry)
        modelContext.insert(secondFoodEntry)

        let subject = MealItemsViewModel(modelContext: modelContext, currentDate: date)
        subject.fetchMealFoodEntries()
        XCTAssertEqual(subject.mealTitle, "Breakfast - 300 Calories")
        XCTAssertEqual(subject.mealFoodEntries, [secondFoodEntry, foodEntry])
    }
}