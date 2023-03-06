//
//  HistoryViewModel.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import HealthKit
import SwiftUI

class HistoryViewModel: ObservableObject {
    private let container: NSPersistentContainer
    private let healthStore: HealthStore
    private var timeFormatter: DateFormatter = DateFormatter()
    var dateForEntries: Date = Date()
    @Published var daySections: [Day] = []

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer = PersistenceController.shared.container) {
        self.healthStore = healthStore
        self.container = container
    }

    @MainActor
    func fetchDaySections() {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        let weekPrior: Date = Calendar.current.startOfDay(for: dateForEntries).addingTimeInterval(-Double(secsPerWeek))
        request.predicate = NSPredicate(format: "timeConsumed >= %@", weekPrior as CVarArg)
        let foodEntriesForWeek: [FoodEntry] = (try? container.viewContext.fetch(request)) ?? []

        var daySections = [Day]()
        foodEntriesForWeek.forEach { foodEntry in
            guard let timeConsumed = foodEntry.timeConsumed else { return }
            let mealType = MealType.mealTypeForDate(timeConsumed)
            let startOfDay = Calendar.current.startOfDay(for: timeConsumed)
            if let foundDaySection = daySections.first(where: { startOfDay == $0.date }) {
                if let foundMeal = foundDaySection.meals.first(where: { $0.mealType == mealType }) {
                    foundMeal.foodEntries.append(foodEntry)
                } else {
                    foundDaySection.meals.append(Meal(mealType: mealType, foodEntries: [foodEntry]))
                }
            } else {
                let daySection = Day(date: startOfDay)
                daySection.meals.append(Meal(mealType: mealType, foodEntries: [foodEntry]))
                daySections.append(daySection)
            }
        }
        self.daySections = daySections.sorted { d1, d2 in
            d1.date > d2.date
        }
    }

    var foodEntries: [FoodEntry] {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries)
        request.predicate = NSPredicate(format: "timeConsumed >= %@", startOfDay as CVarArg)
        return (try? container.viewContext.fetch(request)) ?? []
    }

    var timeConsumedTimeFormatter: DateFormatter {
        timeFormatter.timeStyle = .short
        return timeFormatter
    }

    func deleteEntries(atRow row: Int?, inFoodEntries foodEntries: [FoodEntry]) async {
        guard let row = row else {
            return
        }
        await deleteFoodEntry(foodEntries[row])
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

    func shouldExpandMeal(meal: Meal) -> Bool {
        meal.foodEntries.last?.timeConsumed == daySections.last?.meals.last?.foodEntries.last?.timeConsumed
    }
}
