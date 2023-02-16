//
//  AddEntryViewModel.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import CoreData
import Foundation
import HealthKit
import SwiftUI

struct Suggestion: Hashable {
    let name: String
}

class AddEntryViewModel {
    let container: NSPersistentContainer
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer = PersistenceController.shared.container) {
        self.healthStore = healthStore
        self.container = container
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

    var foodEntries: [FoodEntry] {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries)
        request.predicate = NSPredicate(format: "timeConsumed >= %@", startOfDay as CVarArg)
        return (try? container.viewContext.fetch(request)) ?? []
    }

    func getSuggestions(searchText: String = "", currentDate: Date = Date()) -> [Suggestion] {

        let request = FoodEntry.fetchRequest()

        if searchText.isEmpty { // Show list of suitable suggestions for this time of day
            let mealType = MealType.mealTypeForDate(currentDate)
            let range = mealType.rangeOfPeriod()
            let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries) // Find entries earlier than today as today's result are part of current meal
            request.predicate = NSPredicate(format: "timeConsumed < %@", startOfDay as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)]
            guard let results: [FoodEntry] = (try? container.viewContext.fetch(request)) else {
                return []
            }
            let filteredResults = results.filter { foodEntry in
                guard let date = foodEntry.timeConsumed else { return false }
                let dc = Calendar.current.dateComponents([.hour], from: date)
                return (dc.hour! >= range.startIndex) && (dc.hour! <= range.endIndex)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            return orderedSet.map { $0 as! Suggestion }
        } else {    // Show fuzzy matched strings for this search text
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)]
            guard let results: [FoodEntry] = (try? container.viewContext.fetch(request)) else {
                return []
            }
            let filteredResults = results.filter { foodEntry in
                return foodEntry.foodDescription.fuzzyMatch(searchText)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.foodDescription) })
            return orderedSet.map { $0 as! Suggestion }
        }
    }

    func addFood(foodDescription: String, calories: Int, timeConsumed: Date) async throws {
        let foodEntry = FoodEntry(context: container.viewContext,
                                  foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed)
        try await healthStore.authorize()
        try await healthStore.addFoodEntry(foodEntry)
        try container.viewContext.save()
    }

    func defCaloriesFor(_ name: String) -> Int {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]
        request.predicate = NSPredicate(format: "foodDescription == %@", name as CVarArg)
        return Int(((try? container.viewContext.fetch(request))?.first as? FoodEntry)?.calories ?? 0)
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
