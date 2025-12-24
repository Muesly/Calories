//
//  AddEntryViewModel.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import HealthKit
import SwiftData
import SwiftUI

@Observable
@MainActor
class AddFoodViewModel: ObservableObject {
    let modelContext: ModelContext
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()
    var suggestions: [Suggestion] = []
    var plants: [Plant] = []

    init(
        healthStore: HealthStore,
        modelContext: ModelContext
    ) {
        self.healthStore = healthStore
        self.modelContext = modelContext
    }

    func prompt(for date: Date = Date()) -> String {
        let mealType = MealType.mealTypeForDate(date).rawValue
        return "Enter \(mealType) food or drink..."
    }

    func calorieSearchURL(for foodDescription: String) -> URL {
        let hostName = "https://www.google.co.uk/search"
        let foodDescriptionPercentEncoded = foodDescription.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed)!
        let combinedString = "\(hostName)?q=calories+in+a+\(foodDescriptionPercentEncoded)"
        return URL(string: combinedString)!
    }

    func setDateForEntries(_ date: Date) {
        dateForEntries = date
    }

    func fetchSuggestions(searchText: String = "") async {
        // Perform the fetch work off the main actor using a background ModelContext
        let dateForEntries = self.dateForEntries
        let container = self.modelContext.container

        // Run the heavy work in a detached task and await its result
        let computedSuggestions: [Suggestion] = await Task.detached(priority: .userInitiated) {
            let backgroundContext = ModelContext(container)

            let mealType = MealType.mealTypeForDate(dateForEntries)
            let range = mealType.rangeOfPeriod()
            let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries)

            let results: [FoodEntry]
            if searchText.isEmpty {
                results = backgroundContext.foodResults(
                    for: #Predicate { $0.timeConsumed < startOfDay })
            } else {
                results = backgroundContext.foodResults()
            }

            let filteredResults: [FoodEntry]
            if searchText.isEmpty {
                filteredResults = results.filter {
                    let dc = Calendar.current.dateComponents([.hour], from: $0.timeConsumed)
                    guard let hour = dc.hour else { return false }
                    return (hour >= range.startIndex) && (hour <= range.endIndex)
                }
            } else {
                filteredResults = results.filter { entry in
                    entry.foodDescription.fuzzyMatch(searchText)
                }
            }

            let orderedSet = NSOrderedSet(
                array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            return orderedSet.compactMap { $0 as? Suggestion }
        }.value

        // Update observable state on the main actor
        self.suggestions = computedSuggestions
    }

    @discardableResult
    @MainActor
    func addFood(foodDescription: String, calories: Int, timeConsumed: Date, plants: [Plant])
        async throws -> FoodEntry
    {
        try await healthStore.authorize()
        let ingredientModels: [IngredientEntry] = plants.map { plant in
            // Find image data to put back in
            var imageData: Data?
            if let existingIngredient = modelContext.findIngredient(plant.name, isPlant: true) {
                imageData = existingIngredient.imageData
            }
            return IngredientEntry(plant.name, imageData: imageData, isPlant: true)
        }
        let foodEntry = FoodEntry(
            foodDescription: foodDescription,
            calories: Double(calories),
            timeConsumed: timeConsumed,
            ingredients: ingredientModels
        ).insert(into: modelContext)
        do {
            try modelContext.save()
        } catch {
            print("Failed to add food: \(error)")
        }
        try await healthStore.addFoodEntry(foodEntry)
        return foodEntry
    }

    func addPlant(_ name: String) {
        plants.append(.init(name: name))
    }

    func foodTemplateFor(_ name: String, timeConsumed: Date) -> FoodTemplate {
        let results = modelContext.foodResults(for: #Predicate { $0.foodDescription == name })
        guard let previousEntry = results.first else {
            return FoodTemplate(description: name, calories: 0, dateTime: timeConsumed)
        }
        return FoodTemplate(
            description: previousEntry.foodDescription,
            calories: Int(previousEntry.calories),
            dateTime: timeConsumed,
            plants: (previousEntry.ingredients ?? []).map { $0.name })
    }

    static func shouldClearFields(phase: ScenePhase, date: Date) -> Bool {
        if phase == .active {
            guard let dayDiff = Calendar.current.dateComponents([.day], from: date, to: Date()).day
            else {
                return false
            }
            return dayDiff > 0 ? true : false
        }
        return false
    }
}

extension String {
    func fuzzyMatch(_ needle: String) -> Bool {
        if needle.isEmpty { return true }
        var remainder = needle.lowercased()[...]
        for char in self.lowercased() {
            if char == remainder[remainder.startIndex] {
                remainder.removeFirst()
                if remainder.isEmpty { return true }
            }
        }
        return false
    }
}

struct FoodTemplate {
    let description: String
    let calories: Int
    let dateTime: Date
    let plants: [String]

    init(
        description: String,
        calories: Int,
        dateTime: Date,
        plants: [String] = []
    ) {
        self.description = description
        self.calories = calories
        self.dateTime = dateTime
        self.plants = plants
    }
}
