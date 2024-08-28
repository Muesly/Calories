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
class AddFoodViewModel: ObservableObject {
    let modelContext: ModelContext
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()
    var suggestions: [Suggestion] = []
    var plants: [Plant] = []

    init(healthStore: HealthStore,
         modelContext: ModelContext) {
        self.healthStore = healthStore
        self.modelContext = modelContext
    }

    func prompt(for date: Date = Date()) -> String {
        let mealType = MealType.mealTypeForDate(date).rawValue
        return "Enter \(mealType) food or drink..."
    }

    func calorieSearchURL(for foodDescription: String) -> URL {
        let hostName = "https://www.myfitnesspal.com/nutrition-facts-calories"
        let foodDescriptionPercentEncoded = foodDescription.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        let combinedString = "\(hostName)/\(foodDescriptionPercentEncoded)"
        return URL(string: combinedString)!
    }

    func setDateForEntries(_ date: Date) {
        dateForEntries = date
    }

    func fetchSuggestions(searchText: String = "") {
        if searchText.isEmpty { // Show list of suitable suggestions for this time of day
            let mealType = MealType.mealTypeForDate(dateForEntries)
            let range = mealType.rangeOfPeriod()
            let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries) // Find entries earlier than today as today's result are part of current meal

            let results = modelContext.foodResults(for: #Predicate { $0.timeConsumed < startOfDay })
            let filteredResults = results.filter {
                let dc = Calendar.current.dateComponents([.hour], from: $0.timeConsumed)
                return (dc.hour! >= range.startIndex) && (dc.hour! <= range.endIndex)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            suggestions = orderedSet.map { $0 as! Suggestion }
        } else {    // Show fuzzy matched strings for this search text
            let results = modelContext.foodResults()
            let filteredResults = results.filter { foodEntry in
                return foodEntry.foodDescription.fuzzyMatch(searchText)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            suggestions = orderedSet.map { $0 as! Suggestion }
        }
    }

    @discardableResult
    func addFood(foodDescription: String, calories: Int, timeConsumed: Date, plants: [Plant]) async throws -> FoodEntry {
        try await healthStore.authorize()
        let foodEntry = FoodEntry(foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed,
                                  plants: plants.map { PlantEntry($0.name, timeConsumed: timeConsumed) }).insert(into: modelContext)
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

    func foodTemplateFor(_ name: String) -> FoodTemplate {
        let results = modelContext.foodResults(for: #Predicate { $0.foodDescription == name })
        guard let previousEntry = results.first else {
            return FoodTemplate(description: name, calories: 0)
        }
        return FoodTemplate(description: previousEntry.foodDescription,
                            calories: Int(previousEntry.calories),
                            plants: (previousEntry.plants ?? []).map { $0.name })
    }

    static func shouldClearFields(phase: ScenePhase, date: Date) -> Bool {
        if phase == .active {
            guard let dayDiff = Calendar.current.dateComponents([.day], from: date, to: Date()).day else {
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

    init(description: String,
         calories: Int,
         dateTime: Date = Date(),
         plants: [String] = []) {
        self.description = description
        self.calories = calories
        self.dateTime = dateTime
        self.plants = plants
    }
}
