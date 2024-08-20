//
//  HistoryViewModel.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import HealthKit
import SwiftUI

@Observable
class HistoryViewModel {
    private let viewContext: NSManagedObjectContext
    private let healthStore: HealthStore
    private var timeFormatter: DateFormatter = DateFormatter()
    var dateForEntries: Date = Date()
    var daySections: [Day] = []

    init(healthStore: HealthStore, viewContext: NSManagedObjectContext) {
        self.healthStore = healthStore
        self.viewContext = viewContext
    }

    @MainActor
    func fetchDaySections() {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        let weekPrior: Date = Calendar.current.startOfDay(for: dateForEntries).addingTimeInterval(-Double(secsPerWeek))
        request.predicate = NSPredicate(format: "timeConsumed >= %@", weekPrior as CVarArg)
        let foodEntriesForWeek: [FoodEntry] = (try? viewContext.fetch(request)) ?? []

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
        return (try? viewContext.fetch(request)) ?? []
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
        viewContext.delete(foodEntry)

        do {
            try viewContext.save()
        } catch {
            print("Failed to save delete")
        }
    }

    func shouldExpandMeal(meal: Meal) -> Bool {
        meal.foodEntries.last?.timeConsumed == daySections.last?.meals.last?.foodEntries.last?.timeConsumed
    }

   func expectedPoundLoss() async throws -> Double {
       var burntCalories = 0
       var consumedCalories = 0
       do {
           var date = Date().addingTimeInterval(86400)
           for _ in 0..<365 {
               let consumedCaloriesForDay = try await healthStore.caloriesConsumed(date: date)
               if consumedCaloriesForDay == 0 {
                   date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
                   continue
               }
               consumedCalories += consumedCaloriesForDay

               let bmr = try await healthStore.bmr(date: date)
               let exercise = try await healthStore.exercise(date: date)
               burntCalories += bmr + exercise

               date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
           }
       } catch {
           print("Failed to fetch burnt or consumed data")
       }
       return Double(consumedCalories - burntCalories) / 3500.0
   }
}
