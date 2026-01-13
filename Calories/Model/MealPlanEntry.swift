//
//  MealPlanEntry.swift
//  Calories
//
//  Created by Tony Short on 29/12/2025.
//

import Foundation
import SwiftData

// MARK: - Codable structs for storage

struct StoredMealSelection: Codable {
    var person: String
    var dateTimestamp: Double
    var mealType: String
    var isSelected: Bool
    var recipeName: String?

    init(from selection: MealSelection) {
        self.person = selection.person.rawValue
        self.dateTimestamp = selection.dayMeal.date.timeIntervalSince1970
        self.mealType = selection.dayMeal.mealType.rawValue
        self.isSelected = selection.isSelected
        self.recipeName = selection.recipe?.name
    }

    func toMealSelection(recipes: [RecipeEntry]) -> MealSelection {
        let person = Person(rawValue: self.person) ?? .tony
        let date = Date(timeIntervalSince1970: self.dateTimestamp)
        let mealType = MealType.allCases.first { $0.rawValue == self.mealType } ?? .breakfast
        let recipe = recipes.first { $0.name == self.recipeName }

        return MealSelection(
            person: person,
            dayMeal: .init(mealType: mealType, date: date),
            isSelected: self.isSelected,
            recipe: recipe
        )
    }
}

struct StoredFoodToUseUp: Codable {
    var id: String
    var name: String
    var isFullMeal: Bool
    var isFrozen: Bool

    init(from food: FoodToUseUp) {
        self.id = food.id.uuidString
        self.name = food.name
        self.isFullMeal = food.isFullMeal
        self.isFrozen = food.isFrozen
    }

    func toFoodToUseUp() -> FoodToUseUp {
        FoodToUseUp(name: name, isFullMeal: isFullMeal, isFrozen: isFrozen)
    }
}

// MARK: - MealPlanEntry Model

@Model public class MealPlanEntry {
    @Attribute(.unique) var weekStartDate: Date

    // Stored as JSON-encoded data
    var mealSelectionsData: Data?
    var mealReasonsData: Data?
    var quickMealsData: Data?
    var pinnedMealsData: Data?
    var foodToUseUpData: Data?

    public init(weekStartDate: Date) {
        self.weekStartDate = weekStartDate
    }

    // MARK: - Meal Selections

    var mealSelections: [StoredMealSelection] {
        get {
            guard let data = mealSelectionsData else { return [] }
            return (try? JSONDecoder().decode([StoredMealSelection].self, from: data)) ?? []
        }
        set {
            mealSelectionsData = try? JSONEncoder().encode(newValue)
        }
    }

    func setMealSelections(_ selections: [MealSelection]) {
        mealSelections = selections.map { StoredMealSelection(from: $0) }
    }

    func getMealSelections(recipes: [RecipeEntry]) -> [MealSelection] {
        mealSelections.map { $0.toMealSelection(recipes: recipes) }
    }

    // MARK: - Meal Reasons

    func getMealReasons() -> [PersonMealKey: String] {
        guard let data = mealReasonsData else { return [:] }
        guard let storedReasons = (try? JSONDecoder().decode([String: String].self, from: data))
        else { return [:] }

        var result: [PersonMealKey: String] = [:]
        for (key, reason) in storedReasons {
            // Legacy format support: try to parse old string key
            if let parsedKey = parsePersonMealKeyFromString(key) {
                result[parsedKey] = reason
            }
        }
        return result
    }

    func setMealReasons(_ reasons: [PersonMealKey: String]) {
        let storedReasons = Dictionary(
            uniqueKeysWithValues: reasons.map { key, reason in
                let personMealKey = PersonMealKey(person: key.person, dayMeal: key.dayMeal)
                return (personMealKey.keyString, reason)
            })
        mealReasonsData = try? JSONEncoder().encode(storedReasons)
    }

    // MARK: - Quick Meals

    func getQuickMeals() -> [MealKey: Bool] {
        guard let data = quickMealsData else { return [:] }
        guard let storedMeals = (try? JSONDecoder().decode([String: Bool].self, from: data)) else {
            return [:]
        }

        var result: [MealKey: Bool] = [:]
        for (key, isQuick) in storedMeals {
            if let parsedKey = parseMealKeyFromString(key) {
                result[parsedKey] = isQuick
            }
        }
        return result
    }

    func setQuickMeals(_ quickMeals: [MealKey: Bool]) {
        let storedMeals = Dictionary(
            uniqueKeysWithValues: quickMeals.map { key, isQuick in
                (key.dayMeal.keyString, isQuick)
            })
        quickMealsData = try? JSONEncoder().encode(storedMeals)
    }

    // MARK: - Pinned Meals

    func getPinnedMeals() -> [MealKey: Bool] {
        guard let data = pinnedMealsData else { return [:] }
        guard let storedMeals = (try? JSONDecoder().decode([String: Bool].self, from: data)) else {
            return [:]
        }

        var result: [MealKey: Bool] = [:]
        for (key, isPinned) in storedMeals {
            if let parsedKey = parseMealKeyFromString(key) {
                result[parsedKey] = isPinned
            }
        }
        return result
    }

    func setPinnedMeals(_ pinnedMeals: [MealKey: Bool]) {
        let storedMeals = Dictionary(
            uniqueKeysWithValues: pinnedMeals.map { key, isPinned in
                return (key.dayMeal.keyString, isPinned)
            })
        pinnedMealsData = try? JSONEncoder().encode(storedMeals)
    }

    // MARK: - Key Parsing Helpers

    private func parsePersonMealKeyFromString(_ keyString: String) -> PersonMealKey? {
        let components = keyString.split(
            separator: "-", maxSplits: 2, omittingEmptySubsequences: false
        ).map(String.init)
        guard components.count >= 3 else { return nil }

        let personRawValue = components[0]
        let mealTypeRawValue = components[2]

        guard let person = Person(rawValue: personRawValue),
            let mealType = MealType.allCases.first(where: { $0.rawValue == mealTypeRawValue })
        else {
            return nil
        }

        // For legacy format, assume date string in middle - we'll use today for simplicity
        return PersonMealKey(person: person, dayMeal: DayMeal(mealType: mealType, date: Date()))
            .normalize()
    }

    private func parseMealKeyFromString(_ keyString: String) -> MealKey? {
        let components = keyString.split(
            separator: "-", maxSplits: 1, omittingEmptySubsequences: false
        ).map(String.init)
        guard components.count >= 2 else { return nil }

        let mealTypeRawValue = components[1]
        guard let mealType = MealType.allCases.first(where: { $0.rawValue == mealTypeRawValue })
        else {
            return nil
        }

        return MealKey(dayMeal: DayMeal(mealType: mealType, date: Date())).normalize()
    }

    // MARK: - Food To Use Up

    var foodToUseUp: [StoredFoodToUseUp] {
        get {
            guard let data = foodToUseUpData else { return [] }
            return (try? JSONDecoder().decode([StoredFoodToUseUp].self, from: data)) ?? []
        }
        set {
            foodToUseUpData = try? JSONEncoder().encode(newValue)
        }
    }

    func setFoodToUseUp(_ foods: [FoodToUseUp]) {
        foodToUseUp = foods.map { StoredFoodToUseUp(from: $0) }
    }

    func getFoodToUseUp() -> [FoodToUseUp] {
        foodToUseUp.map { $0.toFoodToUseUp() }
    }
}

extension MealPlanEntry {
    static var byWeekStartDate: SortDescriptor<MealPlanEntry> {
        SortDescriptor(\.weekStartDate, order: .reverse)
    }

    /// Finds or creates a meal plan for the given week
    static func findOrCreate(
        for weekStartDate: Date,
        in modelContext: ModelContext
    ) -> MealPlanEntry {
        let normalizedDate = normalizeToMondayMidnight(weekStartDate)

        var descriptor = FetchDescriptor<MealPlanEntry>(
            predicate: #Predicate { $0.weekStartDate == normalizedDate }
        )
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newEntry = MealPlanEntry(weekStartDate: normalizedDate)
        modelContext.insert(newEntry)
        return newEntry
    }

    /// Normalizes a date to Monday at midnight for consistent week identification
    private static func normalizeToMondayMidnight(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
