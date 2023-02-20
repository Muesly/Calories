//
//  WeeklyChartViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 15/02/2023.
//

import CoreData
import XCTest
@testable import Calories

final class WeeklyChartViewModelTests: XCTestCase {
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

    func testCalloutViewDetails() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 2400
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let currentDate = dc.date!
        let calloutViewDetails = try await subject.calloutViewDetails(for: "Mon", currentDate: currentDate)
        XCTAssertEqual(calloutViewDetails, CallOutViewDetails(bmr: 1900,
                                                              exercise: 800,
                                                              caloriesConsumed: 2400))
        XCTAssertEqual(calloutViewDetails.difference, 300)
        XCTAssertEqual(calloutViewDetails.canEat, -200)
    }

    func testWeeklyDetailsBelowTarger() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 2400
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let currentDate = dc.date!

        await subject.fetchDaysCalorieData()

        XCTAssertEqual(subject.weeklyData, [.init(department: "Production", calories: 300, stat: "Burnt"),
                                            .init(department: "Production", calories: 3200, stat: "To Go"),
                                            .init(department: "Production", calories: 0, stat: "Can Eat")])
    }

    func testWeeklyDetailsAboveTarger() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 12900
        mockHealthStore.exercise = 4800
        mockHealthStore.caloriesConsumed = 14000
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore)
        await subject.fetchDaysCalorieData()

        XCTAssertEqual(subject.weeklyData, [.init(department: "Production", calories: 3500, stat: "Burnt"),
                                            .init(department: "Production", calories: 0, stat: "To Go"),
                                            .init(department: "Production", calories: 200, stat: "Can Eat")])
    }

    func testColourForDifference() async throws {
        var colour = WeeklyChartViewModel.colourForDifference(20)
        XCTAssertEqual(colour, .red)

        colour = WeeklyChartViewModel.colourForDifference(-20)
        XCTAssertEqual(colour, .orange)

        colour = WeeklyChartViewModel.colourForDifference(-501)
        XCTAssertEqual(colour, .green)
    }
}
