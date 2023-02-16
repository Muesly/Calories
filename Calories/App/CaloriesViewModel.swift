//
//  CaloriesViewModel.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import HealthKit
import SwiftUI

class Day: Identifiable {
    let id = UUID()
    let date: Date
    var foodEntries: [FoodEntry]
    private let df = DateFormatter()

    init(date: Date, foodEntries: [FoodEntry]) {
        self.date = date
        self.foodEntries = foodEntries
        df.dateFormat = "EEEE, MMM d"
    }

    var title: String {
        df.string(from: date)
    }
}

class CaloriesViewModel: ObservableObject {
    let container: NSPersistentContainer
    let healthStore: HealthStore
    var dateForEntries: Date = Date()
    private var timeFormatter: DateFormatter = DateFormatter()
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

        let weekPrior: Date = Calendar.current.startOfDay(for: dateForEntries).addingTimeInterval(-(7 * 86400))
        request.predicate = NSPredicate(format: "timeConsumed >= %@", weekPrior as CVarArg)
        let foodEntriesForWeek: [FoodEntry] = (try? container.viewContext.fetch(request)) ?? []

        var daySections = [Day]()
        foodEntriesForWeek.forEach { foodEntry in
            guard let timeConsumed = foodEntry.timeConsumed else { return }
            let startOfDay = Calendar.current.startOfDay(for: timeConsumed)
            if let foundDaySection = daySections.first(where: { startOfDay == $0.date }) {
                foundDaySection.foodEntries.append(foodEntry)
            } else {
                let daySection = Day(date: startOfDay, foodEntries: [foodEntry])
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
}
