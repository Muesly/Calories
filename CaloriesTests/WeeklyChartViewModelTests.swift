//
//  WeeklyChartViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 15/02/2023.
//

import SwiftData
import XCTest
@testable import Calories

final class WeeklyChartViewModelTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testCalloutViewDetails() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 2400
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 0, minute: 0)
        subject.startDate = dc.date!
        let calloutViewDetails = try await subject.calloutViewDetails(for: "Mon")
        XCTAssertEqual(calloutViewDetails, CallOutViewDetails(date: dc.date!.startOfWeek,
                                                              bmr: 1900,
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
        subject.startDate = dc.date!

        await subject.fetchWeeklyData(currentDate: dc.date!.addingTimeInterval(secsPerWeek))

        XCTAssertEqual(subject.weeklyData, [.init(calories: 2100, stat: "Burnt"),
                                            .init(calories: 1400, stat: "To Go"),
                                            .init(calories: 0, stat: "Can Eat")])
    }

    func testWeeklyDetailsAboveTarger() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 1400
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        subject.startDate = dc.date!

        await subject.fetchWeeklyData(currentDate: dc.date!.addingTimeInterval(secsPerWeek))

        XCTAssertEqual(subject.weeklyData, [.init(calories: 3500, stat: "Burnt"),
                                            .init(calories: 0, stat: "To Go"),
                                            .init(calories: 5600, stat: "Can Eat")])
    }

    func testColourForDifference() async throws {
        var colour = WeeklyChartViewModel.colourForDifference(20)
        XCTAssertEqual(colour, .red)

        colour = WeeklyChartViewModel.colourForDifference(-20)
        XCTAssertEqual(colour, .orange)

        colour = WeeklyChartViewModel.colourForDifference(-501)
        XCTAssertEqual(colour, .green)
    }

    func testWeeksPlantData() {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let modelContext = ModelContext.inMemory
        let _ = FoodEntry(foodDescription: "Salmon & Rice",
                                  calories: 350,
                                  timeConsumed: dc.date!, plants: [.init("Rice")]).insert(into: modelContext)
        let _ = FoodEntry(foodDescription: "Beans & Rice",
                                  calories: 250,
                                  timeConsumed: dc.date!, plants: [.init("Rice"), .init("Black Beans")]).insert(into: modelContext)
        let subject = WeeklyChartViewModel(healthStore: MockHealthStore())
        subject.modelContext = modelContext
        subject.fetchWeeklyPlantsData()
        subject.startDate = dc.date!
        XCTAssertEqual(subject.weeklyPlantsData, [WeeklyPlantsStat(numPlants: 2, stat: "Num Plants", date: dc.date!)])
    }
}
