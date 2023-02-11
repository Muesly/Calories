//
//  CaloriesViewModel.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import Foundation
import HealthKit
import SwiftUI

class CalorieStats: ObservableObject {
    let bmr: Int
    let exercise: Int
    var caloriesConsumed: Int
    let deficitGoal = 500
    var combinedExpenditure: Int { bmr + exercise }
    var difference: Int { bmr + exercise - caloriesConsumed }
    var canEat: Int { bmr + exercise - caloriesConsumed - deficitGoal }

    init(bmr: Int = 0,
         exercise: Int = 0,
         caloriesConsumed: Int = 0) {
        self.bmr = bmr
        self.exercise = exercise
        self.caloriesConsumed = caloriesConsumed
    }
}

@MainActor
class CaloriesViewModel: ObservableObject {
    let healthStore: HealthStore
    let container: NSPersistentContainer
    private var dateForEntries: Date = Date()
    var calorieStats = CalorieStats()

    var foodEntries: [FoodEntry] {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries)
        request.predicate = NSPredicate(format: "timeConsumed >= %@", startOfDay as CVarArg)
        return (try? container.viewContext.fetch(request)) ?? []
    }

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer) {
        self.healthStore = healthStore
        self.container = container
    }

    func setDateForEntries(_ date: Date) async {
        dateForEntries = date
    }

    func fetchCaloriesConsumed() async throws {
        calorieStats.caloriesConsumed = try await self.healthStore.caloriesConsumed()
    }

    func fetchStats() async throws {
        calorieStats = try await CalorieStats(bmr: self.healthStore.bmr(),
                                              exercise: self.healthStore.exercise(),
                                              caloriesConsumed: self.healthStore.caloriesConsumed())
        objectWillChange.send()
    }

    func addFood(foodDescription: String, calories: Int, timeConsumed: Date) async throws {
        let foodEntry = FoodEntry(context: container.viewContext,
                                  foodDescription: foodDescription,
                                  calories: Double(calories),
                                  timeConsumed: timeConsumed)
        try await healthStore.authorize()
        try await healthStore.addFoodEntry(foodEntry)
        try await fetchCaloriesConsumed()
        try container.viewContext.save()
        objectWillChange.send()
    }

    func deleteEntries(offsets: IndexSet) {
        guard let foodEntry = offsets.map({ foodEntries[$0] }).first else {
            return
        }
        Task {
            await deleteFoodEntry(foodEntry)
        }
    }

    func deleteFoodEntry(_ foodEntry: FoodEntry) async {
        do {
            try await healthStore.deleteFoodEntry(foodEntry)
        } catch {
            print("Failed to save delete in Health")
        }
        container.viewContext.delete(foodEntry)

        do {
            try container.viewContext.save()
        } catch {
            print("Failed to save delete")
        }
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
