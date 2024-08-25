//
//  AddEntryViewModel.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import CoreData
import Foundation
import HealthKit
import SwiftData
import SwiftUI

@Observable
class AddFoodViewModel: ObservableObject {
    let viewContext: NSManagedObjectContext
    let modelContext: ModelContext
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()
    var suggestions: [Suggestion] = []
    var plants: [Plant] = []

    init(healthStore: HealthStore,
         viewContext: NSManagedObjectContext,
         modelContext: ModelContext) {
        self.healthStore = healthStore
        self.viewContext = viewContext
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
        let request = FoodEntryCD.fetchRequest()

        if searchText.isEmpty { // Show list of suitable suggestions for this time of day
            let mealType = MealType.mealTypeForDate(dateForEntries)
            let range = mealType.rangeOfPeriod()
            let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries) // Find entries earlier than today as today's result are part of current meal
            request.predicate = NSPredicate(format: "timeConsumed < %@", startOfDay as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntryCD.timeConsumed, ascending: false)]
            guard let results: [FoodEntryCD] = (try? viewContext.fetch(request)) else {
                suggestions = []
                return
            }
            let filteredResults = results.filter { foodEntry in
                guard let date = foodEntry.timeConsumed else { return false }
                let dc = Calendar.current.dateComponents([.hour], from: date)
                return (dc.hour! >= range.startIndex) && (dc.hour! <= range.endIndex)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            suggestions = orderedSet.map { $0 as! Suggestion }
        } else {    // Show fuzzy matched strings for this search text
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntryCD.timeConsumed, ascending: false)]
            guard let results: [FoodEntryCD] = (try? viewContext.fetch(request)) else {
                suggestions = []
                return
            }
            let filteredResults = results.filter { foodEntry in
                return foodEntry.foodDescription.fuzzyMatch(searchText)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            suggestions = orderedSet.map { $0 as! Suggestion }
        }
    }

    func addFood(foodDescription: String, calories: Int, timeConsumed: Date, plants: [Plant]) async throws -> FoodEntry {
        try await healthStore.authorize()
        let foodEntry = FoodEntry(foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed,
                                  plants: plants.map { PlantEntry($0.name, timeConsumed: timeConsumed) })
        modelContext.insert(foodEntry)
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

    func foodTemplateFor(_ name: String) -> FoodEntry {
        let fetchDescriptor = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.foodDescription == name },
                                                         sortBy: [FoodEntry.mostRecent])
        guard let previousEntry = try? modelContext.fetch(fetchDescriptor).first else {
            return FoodEntry(foodDescription: name, calories: 0, timeConsumed: Date(), plants: [])
        }
        return previousEntry
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
