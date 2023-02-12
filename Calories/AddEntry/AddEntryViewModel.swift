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

class AddEntryViewModel: ObservableObject {
    @ObservedObject var calorieStats: CalorieStats
    let container: NSPersistentContainer
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer = PersistenceController.shared.container,
         calorieStats: CalorieStats) {
        self.healthStore = healthStore
        self.container = container
        self.calorieStats = calorieStats
    }

    func setDateForEntries(_ date: Date) async {
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

    func getSuggestions(currentDate: Date = Date()) -> [Suggestion] {
        let request = FoodEntry.fetchRequest()
        let mealType = MealType.mealTypeForDate(currentDate)
        let range = mealType.rangeOfPeriod()
        let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries) // Find entries earlier than today as today's result are part of current meal
        request.predicate = NSPredicate(format: "timeConsumed < %@", startOfDay as CVarArg)
        guard let results: [FoodEntry] = (try? container.viewContext.fetch(request)) else {
            return []
        }
        let filteredResults = results.filter { foodEntry in
            guard let date = foodEntry.timeConsumed else { return false }
            let dc = Calendar.current.dateComponents([.hour], from: date)
            return (dc.hour! >= range.startIndex) && (dc.hour! <= range.endIndex)
        }
        return Array(Set(filteredResults.map { Suggestion(name: $0.foodDescription) }))
    }

    func addFood(foodDescription: String, calories: Int, timeConsumed: Date) async throws {
        let foodEntry = FoodEntry(context: container.viewContext,
                                  foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed)
        try await healthStore.authorize()
        try await healthStore.addFoodEntry(foodEntry)
        try container.viewContext.save()
        objectWillChange.send()
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

    func fetchCaloriesConsumed() async throws {
        calorieStats.fetchCaloriesConsumed()
    }
}
