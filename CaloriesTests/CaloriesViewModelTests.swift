//
//  CaloriesTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftData
import XCTest
@testable import Calories

final class CaloriesViewModelTests: XCTestCase {
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
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testCanDeleteFoodEntry() async throws {
        let _ = FoodEntry(foodDescription: "Some food",
                                  calories: Double(100),
                                  timeConsumed: dateFromComponents).insert(into: modelContext)
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
        subject.dateForEntries = dateFromComponents
        let entry1 = FoodEntry(foodDescription: "Some food",
                               calories: Double(100),
                               timeConsumed: dateFromComponents).insert(into: modelContext)
        let entry2 = FoodEntry(foodDescription: "Some more food",
                               calories: Double(200),
                               timeConsumed: dateFromComponents.addingTimeInterval(600)).insert(into: modelContext)

        let foodEntries = subject.foodEntries
        XCTAssertEqual(foodEntries, [entry2, entry1])
    }

    func testFetchingDaySections() async throws {
        let date = dateFromComponents
        subject.dateForEntries = date
        let entry1 = FoodEntry(foodDescription: "Some food",
                               calories: Double(100),
                               timeConsumed: date).insert(into: modelContext)
        let entry2 = FoodEntry(foodDescription: "Some more food",
                               calories: Double(200),
                               timeConsumed: date.addingTimeInterval(90600)).insert(into: modelContext)
        let entry3 = FoodEntry(foodDescription: "Even more food",
                               calories: Double(100),
                               timeConsumed: date.addingTimeInterval(90700)).insert(into: modelContext)
        let entry4 = FoodEntry(foodDescription: "Late addition",
                               calories: Double(50),
                               timeConsumed: date.addingTimeInterval(112700)).insert(into: modelContext)

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

        _ = FoodEntry(foodDescription: "Some food",
                      calories: Double(100),
                      timeConsumed: dateFromComponents).insert(into: modelContext)
        await subject.fetchDaySections()
        XCTAssertEqual(subject.daySections.first?.title, "Sunday, Jan 1")
        XCTAssertEqual(subject.daySections.first?.meals.first?.summary, "Morning Snack (100 cals)")
    }
}
