//
//  MealItemsViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 11/02/2023.
//

import CoreData
import XCTest
@testable import Calories

final class MealItemsViewModelTests: XCTestCase {
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

    func testMealTitlesDependingOnTimeOfDay() async throws {
        let subject = MealItemsViewModel(foodEntries: [])
        var dc = DateComponents(calendar: Calendar.current)
        dc.hour = 8
        XCTAssertEqual(subject.getMealTitle(currentDate: dc.date!), "Breakfast - 0 Calories")
        dc.hour = 10
        XCTAssertEqual(subject.getMealTitle(currentDate: dc.date!), "Morning Snack - 0 Calories")
        dc.hour = 12
        XCTAssertEqual(subject.getMealTitle(currentDate: dc.date!), "Lunch - 0 Calories")
        dc.hour = 14
        XCTAssertEqual(subject.getMealTitle(currentDate: dc.date!), "Afternoon Snack - 0 Calories")
        dc.hour = 17
        XCTAssertEqual(subject.getMealTitle(currentDate: dc.date!), "Dinner - 0 Calories")
        dc.hour = 20
        XCTAssertEqual(subject.getMealTitle(currentDate: dc.date!), "Evening Snack - 0 Calories")
    }

    func testMealTitlesWithCalories() throws {
        let date = DateComponents(calendar: Calendar.current,
                                  year: 2023,
                                  month: 1,
                                  day: 1,
                                  hour: 8).date!
        let oldFoodEntry = FoodEntry(context: context,
                                     foodDescription: "Some old food entry",
                                     calories: Double(100),
                                     timeConsumed: date.addingTimeInterval(-secsPerDay))
        let foodEntry = FoodEntry(context: context,
                      foodDescription: "Some food",
                      calories: Double(200),
                      timeConsumed: date)
        let secondFoodEntry = FoodEntry(context: context,
                                        foodDescription: "Some more food",
                                        calories: Double(100),
                                        timeConsumed: date.addingTimeInterval(7199))    // Right at end of breakfast time
        let subject = MealItemsViewModel(foodEntries: [oldFoodEntry, foodEntry, secondFoodEntry])
        try context.save()
        XCTAssertEqual(subject.getMealTitle(currentDate: date), "Breakfast - 300 Calories")
        XCTAssertEqual(subject.getMealFoodEntries(currentDate: date), [secondFoodEntry, foodEntry])
    }

    func testMealItemsWithinTimePeriod() async throws {
    }
}
