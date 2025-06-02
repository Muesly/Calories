//
//  AddFoodViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import SwiftData
import Testing

@testable import Calories

@MainActor
final class AddFoodViewModelTests {
    var subject: AddFoodViewModel!
    var mockHealthStore: MockHealthStore!
    var modelContext: ModelContext!

    init() {
        modelContext = ModelContext.inMemory
        mockHealthStore = MockHealthStore()
        subject = AddFoodViewModel(healthStore: mockHealthStore, modelContext: modelContext)
    }

    deinit {
        subject = nil
        mockHealthStore = nil
        modelContext = nil
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    @Test func givenPermissionGrantedCanAddCalories() async throws {
        try await subject.addFood(
            foodDescription: "Some food",
            calories: 100,
            timeConsumed: dateFromComponents(),
            plants: [])
        let foodEntry = modelContext.foodResults(
            for: #Predicate { $0.foodDescription == "Some food" }
        ).first
        try #require(foodEntry != nil)
        #expect(foodEntry?.foodDescription == "Some food")
    }

    @Test func deniedPermissionGrantedCanAddFoodEntry() async throws {
        mockHealthStore.authorizeError = HealthStoreError.errorNoHealthDataAvailable
        do {
            try await subject.addFood(
                foodDescription: "Some food",
                calories: 100,
                timeConsumed: dateFromComponents(),
                plants: [])
        } catch let healthStoreError as HealthStoreError {
            #expect(healthStoreError == HealthStoreError.errorNoHealthDataAvailable)
        }
        #expect(
            modelContext.foodResults(for: #Predicate { $0.foodDescription == "Some food" }).isEmpty)
    }

    @Test func clearDownOfInProgressDetailsAfterDay() async {
        let shouldClear = AddFoodViewModel.shouldClearFields(
            phase: .active, date: Date().addingTimeInterval(-secsPerDay))
        #expect(shouldClear)
    }

    @Test func noClearDownOfInProgressDetailsOnSameDay() async {
        let shouldClear = AddFoodViewModel.shouldClearFields(phase: .active, date: Date())
        #expect(!shouldClear)
    }

    @Test func whenNoSuggestionsShownForAFoodEntryWhenFoodFromToday() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(
            foodDescription: "Some more food",
            calories: 100,
            timeConsumed: date,
            plants: [])
        subject.fetchSuggestions()
        #expect(subject.suggestions.isEmpty)
    }

    @Test func whenNoSuggestionsShownForAFoodEntryWhenFoodNotInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(
            foodDescription: "Some more food",
            calories: 100,
            timeConsumed: date.addingTimeInterval(-secsPerDay - (3 * 3600)),
            plants: [])
        subject.fetchSuggestions()
        #expect(subject.suggestions.isEmpty)
    }

    @Test func whenSuggestionsShownForAFoodEntryWhenFoodInSameMealTime() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(
            foodDescription: "Some more food",
            calories: 100,
            timeConsumed: date.addingTimeInterval(-secsPerDay),
            plants: [])
        subject.fetchSuggestions()
        #expect(subject.suggestions == [Suggestion(name: "Some more food")])
    }

    @Test func suggestionsFuzzyMatched() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(
            foodDescription: "Some more food",
            calories: 100,
            timeConsumed: date.addingTimeInterval(-secsPerDay),
            plants: [])
        subject.fetchSuggestions(searchText: "more")
        #expect(subject.suggestions == [Suggestion(name: "Some more food")])

        subject.fetchSuggestions(searchText: "mxe")  // Shouldn't return results
        #expect(subject.suggestions.isEmpty)
    }

    @Test func defaultCaloriesForTwoSimilarFoodEntriesReturnsLatest() async throws {
        let date = dateFromComponents()
        subject.setDateForEntries(date)
        try await subject.addFood(
            foodDescription: "Cornflakes",
            calories: 200,
            timeConsumed: date.addingTimeInterval(-3600),
            plants: [])
        try await subject.addFood(
            foodDescription: "Cornflakes",
            calories: 100,
            timeConsumed: date.addingTimeInterval(-1800),
            plants: [])
        let defCalories = subject.foodTemplateFor("Cornflakes", timeConsumed: date).calories

        #expect(defCalories == 100)
        #expect(subject.modelContext.foodResults().count == 2)
    }

    @Test func prompt() {
        let date = dateFromComponents()
        #expect(subject.prompt(for: date) == "Enter Morning Snack food or drink...")
    }

    @Test func calorieSearchURL() {
        #expect(
            subject.calorieSearchURL(for: "Banana Cake").absoluteString
                == "https://www.google.co.uk/search?q=calories+in+a+Banana%20Cake")
    }
}
