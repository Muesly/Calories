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
        var dc = DateComponents(calendar: Calendar.current)
        dc.hour = 8
        let breakfastSubject = MealItemsViewModel(viewContext: context, currentDate: dc.date!)
        XCTAssertEqual(breakfastSubject.mealTitle, "Breakfast - 0 Calories")

        dc.hour = 10
        let morningSnackSubject = MealItemsViewModel(viewContext: context, currentDate: dc.date!)
        XCTAssertEqual(morningSnackSubject.mealTitle, "Morning Snack - 0 Calories")

        dc.hour = 12
        let lunchSubject = MealItemsViewModel(viewContext: context, currentDate: dc.date!)
        XCTAssertEqual(lunchSubject.mealTitle, "Lunch - 0 Calories")

        dc.hour = 14
        let afternoonSnackSubject = MealItemsViewModel(viewContext: context, currentDate: dc.date!)
        XCTAssertEqual(afternoonSnackSubject.mealTitle, "Afternoon Snack - 0 Calories")

        dc.hour = 17
        let dinnerSubject = MealItemsViewModel(viewContext: context, currentDate: dc.date!)
        XCTAssertEqual(dinnerSubject.mealTitle, "Dinner - 0 Calories")

        dc.hour = 20
        let eveningSnackSubject = MealItemsViewModel(viewContext: context, currentDate: dc.date!)
        XCTAssertEqual(eveningSnackSubject.mealTitle, "Evening Snack - 0 Calories")
    }

    func testMealTitlesWithCalories() throws {
        let date = DateComponents(calendar: Calendar.current,
                                  year: 2023,
                                  month: 1,
                                  day: 1,
                                  hour: 8).date!
        let _ = FoodEntry(context: context,
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
        try context.save()
        let subject = MealItemsViewModel(viewContext: context, currentDate: date)
        subject.fetchMealFoodEntries()
        XCTAssertEqual(subject.mealTitle, "Breakfast - 300 Calories")
        XCTAssertEqual(subject.mealFoodEntries, [secondFoodEntry, foodEntry])
    }
}
