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

@Observable
class AddFoodViewModel: ObservableObject {
    let viewContext: NSManagedObjectContext
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()
    var suggestions: [Suggestion] = []
    
    init(healthStore: HealthStore,
         viewContext: NSManagedObjectContext) {
        self.healthStore = healthStore
        self.viewContext = viewContext
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

        let request = FoodEntry.fetchRequest()

        if searchText.isEmpty { // Show list of suitable suggestions for this time of day
            let mealType = MealType.mealTypeForDate(dateForEntries)
            let range = mealType.rangeOfPeriod()
            let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries) // Find entries earlier than today as today's result are part of current meal
            request.predicate = NSPredicate(format: "timeConsumed < %@", startOfDay as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)]
            guard let results: [FoodEntry] = (try? viewContext.fetch(request)) else {
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
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)]
            guard let results: [FoodEntry] = (try? viewContext.fetch(request)) else {
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

    func addFood(foodDescription: String, calories: Int, timeConsumed: Date, plants: [Plant]) async throws {
        try await healthStore.authorize()
        let foodEntry = FoodEntry(context: viewContext,
                                  foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed)
        try await healthStore.addFoodEntry(foodEntry)
        try viewContext.save()
    }

    func defCaloriesFor(_ name: String) -> Int {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]
        request.predicate = NSPredicate(format: "foodDescription == %@", name as CVarArg)
        return Int(((try? viewContext.fetch(request))?.first as? FoodEntry)?.calories ?? 0)
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
