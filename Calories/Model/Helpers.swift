//
//  Helpers.swift
//  Calories
//
//  Created by Tony Short on 02/03/2023.
//

import SwiftData
import Foundation

let secsPerDay = TimeInterval(86400)
let secsPerWeek = TimeInterval(7 * secsPerDay)

extension ModelContext {
    static var inMemory: ModelContext {
        ModelContext(try! ModelContainer(for: FoodEntry.self, PlantEntry.self, ExerciseEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }

    @MainActor
    func foodResults(for predicate: Predicate<FoodEntry>? = nil,
                     sortBy: [SortDescriptor<FoodEntry>] = [FoodEntry.mostRecent]) -> [FoodEntry] {
        let fetchDescriptor = FetchDescriptor<FoodEntry>(predicate: predicate,
                                                         sortBy: sortBy)
        do {
            return try fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

    func plantResults(for predicate: Predicate<PlantEntry>? = nil,
                     sortBy: [SortDescriptor<PlantEntry>] = []) -> [PlantEntry] {
        let fetchDescriptor = FetchDescriptor<PlantEntry>(predicate: predicate,
                                                         sortBy: sortBy)
        do {
            return try fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

    func findPlant(_ plant: String) -> PlantEntry? {
        let fetchDescriptor = FetchDescriptor<PlantEntry>(predicate: #Predicate { $0.name == plant })
        let firstMatch = try? fetch(fetchDescriptor).first
        return firstMatch
    }

    func exerciseResults(for predicate: Predicate<ExerciseEntry>? = nil,
                 sortBy: [SortDescriptor<ExerciseEntry>] = [ExerciseEntry.mostRecent]) -> [ExerciseEntry] {
        let fetchDescriptor = FetchDescriptor<ExerciseEntry>(predicate: predicate,
                                                         sortBy: sortBy)
        do {
            return try fetch(fetchDescriptor)
        } catch {
            return []
        }
    }
}

extension Formatter {
    static var integer: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }
}
