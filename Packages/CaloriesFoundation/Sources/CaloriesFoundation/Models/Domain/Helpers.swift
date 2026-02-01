//
//  Helpers.swift
//  Calories
//
//  Created by Tony Short on 02/03/2023.
//

import Foundation
import SwiftData

let secsPerDay = TimeInterval(86400)
let secsPerWeek = TimeInterval(7 * secsPerDay)

extension ModelContext {
    static var inMemory: ModelContext {
        ModelContext(
            try! ModelContainer(
                for: FoodEntry.self,
                IngredientEntry.self,
                ExerciseEntry.self,
                RecipeEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }

    func foodResults(
        for predicate: Predicate<FoodEntry>? = nil,
        sortBy: [SortDescriptor<FoodEntry>] = [FoodEntry.mostRecent]
    ) -> [FoodEntry] {
        let fetchDescriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: sortBy)
        do {
            return try fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

    func ingredientResults(
        for predicate: Predicate<IngredientEntry>? = nil,
        sortBy: [SortDescriptor<IngredientEntry>] = []
    ) -> [IngredientEntry] {
        let fetchDescriptor = FetchDescriptor<IngredientEntry>(
            predicate: predicate,
            sortBy: sortBy)
        do {
            return try fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

    func findIngredient(_ name: String, isPlant: Bool = true) -> IngredientEntry? {
        let fetchDescriptor = FetchDescriptor<IngredientEntry>(
            predicate: #Predicate { $0.name == name && $0.isPlant == isPlant })
        let firstMatch = try? fetch(fetchDescriptor).first
        return firstMatch
    }

    // Backward compatibility
    func plantResults(
        for predicate: Predicate<IngredientEntry>? = nil,
        sortBy: [SortDescriptor<IngredientEntry>] = []
    ) -> [IngredientEntry] {
        let enrichedPredicate: Predicate<IngredientEntry>? = #Predicate { $0.isPlant }
        return ingredientResults(for: enrichedPredicate, sortBy: sortBy)
    }

    func findPlant(_ plant: String) -> IngredientEntry? {
        findIngredient(plant, isPlant: true)
    }

    func exerciseResults(
        for predicate: Predicate<ExerciseEntry>? = nil,
        sortBy: [SortDescriptor<ExerciseEntry>] = [ExerciseEntry.mostRecent]
    ) -> [ExerciseEntry] {
        let fetchDescriptor = FetchDescriptor<ExerciseEntry>(
            predicate: predicate,
            sortBy: sortBy)
        do {
            return try fetch(fetchDescriptor)
        } catch {
            return []
        }
    }

    func recipeResults(
        for predicate: Predicate<RecipeEntry>? = nil,
        sortBy: [SortDescriptor<RecipeEntry>] = [RecipeEntry.byName]
    ) -> [RecipeEntry] {
        let fetchDescriptor = FetchDescriptor<RecipeEntry>(
            predicate: predicate,
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
