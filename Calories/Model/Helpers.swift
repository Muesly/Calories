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
}
