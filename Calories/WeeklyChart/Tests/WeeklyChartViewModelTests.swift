//
//  WeeklyChartViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 15/02/2023.
//

import SwiftData
import XCTest

@testable import Calories

@MainActor
final class WeeklyChartViewModelTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testWeeklyDetailsBelowTarger() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 2400
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore, currentDate: date)
        subject.startDate = date

        await subject.fetchWeeklyData(currentDate: dc.date!.addingTimeInterval(secsPerWeek))

        XCTAssertEqual(
            subject.weeklyData,
            [
                .init(weightLossInLbs: 0.6, stat: "Good"),
                .init(weightLossInLbs: 0.4, stat: "To Go"),
                .init(weightLossInLbs: 0, stat: "Can Eat"),
            ])
    }

    func testWeeklyDetailsAboveTarger() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 1400
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let date = dc.date!
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore, currentDate: date)
        subject.startDate = dc.date!

        await subject.fetchWeeklyData(currentDate: dc.date!.addingTimeInterval(secsPerWeek))

        XCTAssertEqual(
            subject.weeklyData,
            [
                .init(weightLossInLbs: 1.0, stat: "Good"),
                .init(weightLossInLbs: 0, stat: "To Go"),
                .init(weightLossInLbs: 1.6, stat: "Can Eat"),
            ])
    }

    func testColourForDifference() async throws {
        var colour = WeeklyChartViewModel.colourForDifference(20)
        XCTAssertEqual(colour, .red)

        colour = WeeklyChartViewModel.colourForDifference(-20)
        XCTAssertEqual(colour, .orange)

        colour = WeeklyChartViewModel.colourForDifference(-501)
        XCTAssertEqual(colour, .green)
    }

    func testWeeksPlantData() throws {
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let modelContext = ModelContext.inMemory
        let _ = FoodEntry(
            foodDescription: "Salmon & Rice",
            calories: 350,
            timeConsumed: dc.date!, ingredients: [.init("Rice", isPlant: true)]
        ).insert(into: modelContext)
        let _ = FoodEntry(
            foodDescription: "Beans & Rice",
            calories: 250,
            timeConsumed: dc.date!,
            ingredients: [.init("Rice", isPlant: true), .init("Black Beans", isPlant: true)]
        ).insert(into: modelContext)
        try modelContext.save()
        let mockIDGenerator = MockIDGenerator()
        let date = dc.date!
        let subject = WeeklyChartViewModel(
            healthStore: MockHealthStore(), idGenerator: mockIDGenerator, currentDate: date)
        subject.modelContext = modelContext
        subject.startDate = date
        subject.fetchWeeklyPlantsData()
        XCTAssertEqual(
            subject.weeklyPlantsData,
            [
                WeeklyPlantsStat(id: "1", numPlants: 2, stat: "Eaten"),
                WeeklyPlantsStat(id: "2", numPlants: 28, stat: "To Go"),
                WeeklyPlantsStat(id: "3", numPlants: 0, stat: "Abundance"),
            ])
    }

    func testWeeksPlantDataWithAbundance() throws {
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let modelContext = ModelContext.inMemory
        let _ = FoodEntry(
            foodDescription: "Salmon & Rice",
            calories: 350,
            timeConsumed: dc.date!, ingredients: [.init("Rice", isPlant: true)]
        ).insert(into: modelContext)
        let _ = FoodEntry(
            foodDescription: "Beans & Rice",
            calories: 250,
            timeConsumed: dc.date!,
            ingredients: [.init("Rice", isPlant: true), .init("Black Beans", isPlant: true)]
        ).insert(into: modelContext)
        try modelContext.save()
        let mockIDGenerator = MockIDGenerator()
        let date = dc.date!
        let subject = WeeklyChartViewModel(
            healthStore: MockHealthStore(), idGenerator: mockIDGenerator, currentDate: date)
        subject.modelContext = modelContext
        subject.plantGoal = 0
        subject.startDate = date
        subject.fetchWeeklyPlantsData()
        XCTAssertEqual(
            subject.weeklyPlantsData,
            [
                WeeklyPlantsStat(id: "1", numPlants: 0, stat: "Eaten"),
                WeeklyPlantsStat(id: "2", numPlants: 0, stat: "To Go"),
                WeeklyPlantsStat(id: "3", numPlants: 2, stat: "Abundance"),
            ])
    }
}

class MockIDGenerator: IDGeneratorType {
    var currentID = 0
    func generate() -> String {
        currentID += 1
        return "\(currentID)"
    }

}
