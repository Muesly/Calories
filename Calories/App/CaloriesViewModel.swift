//
//  CaloriesViewModel.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import HealthKit
import SwiftUI

class CaloriesViewModel {
    let container: NSPersistentContainer
    let healthStore: HealthStore
    private var dateForEntries: Date = Date()

    init(healthStore: HealthStore = HKHealthStore(),
         container: NSPersistentContainer = PersistenceController.shared.container) {
        self.healthStore = healthStore
        self.container = container
    }

    var foodEntries: [FoodEntry] {
        let request = FoodEntry.fetchRequest()
        let sort = NSSortDescriptor(keyPath: \FoodEntry.timeConsumed, ascending: false)
        request.sortDescriptors = [sort]

        let startOfDay: Date = Calendar.current.startOfDay(for: dateForEntries)
        request.predicate = NSPredicate(format: "timeConsumed >= %@", startOfDay as CVarArg)
        return (try? container.viewContext.fetch(request)) ?? []
    }

    func deleteEntries(offsets: IndexSet) async {
        guard let foodEntry = offsets.map({ foodEntries[$0] }).first else {
            return
        }
        await deleteFoodEntry(foodEntry)
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

        do {
//            try await calorieStats.fetchCaloriesConsumed()
        } catch {
            print("Failed to update calories consumed")
        }
    }
}
