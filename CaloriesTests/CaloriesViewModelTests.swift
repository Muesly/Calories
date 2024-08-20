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

    var viewContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        viewContext = PersistenceController(inMemory: true).container.viewContext
        subject = HistoryViewModel(healthStore: MockHealthStore(), viewContext: viewContext)
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
        _ = FoodEntry(context: viewContext,
                      foodDescription: "Some food",
                      calories: Double(100),
                      timeConsumed: dateFromComponents)
        try viewContext.save()

        let fetchRequest: NSFetchRequest<FoodEntry> = FoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "foodDescription == %@", "Some food")
        let preResult = try? viewContext.fetch(fetchRequest)
        guard let foodEntry = preResult?.first else {
            XCTFail("Expected food entry")
            return
        }
        await subject.deleteFoodEntry(foodEntry)
        let postResult = try? viewContext.fetch(fetchRequest)
        XCTAssertEqual(postResult?.count, 0)
    }

    func testFetchingFoodEntriesSortsMostRecentFirst() async throws {
        subject.dateForEntries = dateFromComponents
        let entry1 = FoodEntry(context: viewContext,
                               foodDescription: "Some food",
                               calories: Double(100),
                               timeConsumed: dateFromComponents)
        let entry2 = FoodEntry(context: viewContext,
                               foodDescription: "Some more food",
                               calories: Double(200),
                               timeConsumed: dateFromComponents.addingTimeInterval(600))
        try viewContext.save()

        let foodEntries = subject.foodEntries
        XCTAssertEqual(foodEntries, [entry2, entry1])
    }

    func testFetchingDaySections() async throws {
        let date = dateFromComponents
        subject.dateForEntries = date
        let entry1 = FoodEntry(context: viewContext,
                               foodDescription: "Some food",
                               calories: Double(100),
                               timeConsumed: date)
        let entry2 = FoodEntry(context: viewContext,
                               foodDescription: "Some more food",
                               calories: Double(200),
                               timeConsumed: date.addingTimeInterval(90600))
        let entry3 = FoodEntry(context: viewContext,
                               foodDescription: "Even more food",
                               calories: Double(100),
                               timeConsumed: date.addingTimeInterval(90700))
        let entry4 = FoodEntry(context: viewContext,
                               foodDescription: "Late addition",
                               calories: Double(50),
                               timeConsumed: date.addingTimeInterval(112700))
        try viewContext.save()

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

        _ = FoodEntry(context: viewContext,
                      foodDescription: "Some food",
                      calories: Double(100),
                      timeConsumed: dateFromComponents)
        try viewContext.save()
        await subject.fetchDaySections()
        XCTAssertEqual(subject.daySections.first?.title, "Sunday, Jan 1")
        XCTAssertEqual(subject.daySections.first?.meals.first?.summary, "Morning Snack (100 cals)")
    }
}
