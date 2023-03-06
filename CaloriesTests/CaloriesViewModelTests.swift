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
    var subject: HistoryViewModel!

    var container: NSPersistentContainer {
        controller.container
    }
    var context: NSManagedObjectContext {
        container.viewContext
    }

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
        subject = HistoryViewModel(healthStore: MockHealthStore(), container: container)
    }

    override func tearDownWithError() throws {
        controller = nil
        subject = nil
    }

    private var dateFromComponents: Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testCanDeleteFoodEntry() async throws {
        _ = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: dateFromComponents)
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
        subject.dateForEntries = dateFromComponents
        let entry1 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: dateFromComponents)
        let entry2 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some more food",
                                  calories: Double(200),
                                  timeConsumed: dateFromComponents.addingTimeInterval(600))
        try container.viewContext.save()

        let foodEntries = subject.foodEntries
        XCTAssertEqual(foodEntries, [entry2, entry1])
    }

    func testFetchingDaySections() async throws {
        let date = dateFromComponents
        subject.dateForEntries = date
        let entry1 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: date)
        let entry2 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some more food",
                                  calories: Double(200),
                                  timeConsumed: date.addingTimeInterval(90600))
        let entry3 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Even more food",
                                  calories: Double(100),
                                  timeConsumed: date.addingTimeInterval(90700))
        let entry4 = FoodEntry(context: container.viewContext,
                                  foodDescription: "Late addition",
                                  calories: Double(50),
                                  timeConsumed: date.addingTimeInterval(112700))
        try container.viewContext.save()

        await subject.fetchDaySections()
        let expectedDay1 = Day(date: Calendar.current.startOfDay(for: date.addingTimeInterval(secsPerDay)))
        expectedDay1.meals.append(Meal(mealType: .dinner, foodEntries: [entry4]))
        expectedDay1.meals.append(Meal(mealType: .lunch, foodEntries: [entry3, entry2]))
        let expectedDay2 = Day(date: Calendar.current.startOfDay(for: date))
        expectedDay2.meals.append(Meal(mealType: .morningSnack, foodEntries: [entry1]))

        XCTAssertEqual(subject.daySections, [expectedDay1, expectedDay2])
    }

    func testGettingDayTitleAndMealSummaryInHistoryView() async throws {
        subject.dateForEntries = dateFromComponents

        _ = FoodEntry(context: container.viewContext,
                                  foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: dateFromComponents)
        try container.viewContext.save()
        await subject.fetchDaySections()
        XCTAssertEqual(subject.daySections.first?.title, "Sunday, Jan 1")
        XCTAssertEqual(subject.daySections.first?.meals.first?.summary, "Morning Snack (100 cals)")
    }
}

class MockHealthStore: HealthStore {
    var authorizeError: Error?
    var bmr: Int = 0
    var exercise: Int = 0
    var caloriesConsumed: Int = 0
    var caloriesBurned: Int = 0
    var weight: Double = 0

    func authorize() async throws {
        guard let error = authorizeError else {
            return
        }
        throw error
    }

    func bmr(date: Date) async throws -> Int {
        bmr
    }

    func exercise(date: Date) async throws -> Int {
        exercise
    }

    func caloriesConsumed(date: Date) async throws -> Int {
        caloriesConsumed
    }

    func weight(date: Date?) async throws -> Double {
        weight
    }

    func addFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed += Int(foodEntry.calories)
    }

    func deleteFoodEntry(_ foodEntry: Calories.FoodEntry) async throws {
        caloriesConsumed -= Int(foodEntry.calories)
    }

    func addExerciseEntry(_ exerciseEntry: Calories.ExerciseEntry) async throws {
        caloriesBurned += exerciseEntry.calories
    }

    func weight(fromDate: Date, toDate: Date) async throws -> Double? {
        weight
    }

    func addWeightEntry(_ weightEntry: Calories.WeightEntry) async throws {
        weight = Double(weightEntry.weight)
    }
}
