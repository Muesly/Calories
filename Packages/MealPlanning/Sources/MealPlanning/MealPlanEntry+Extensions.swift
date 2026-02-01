//
//  File.swift
//  MealPlanning
//
//  Created by Tony Short on 01/02/2026.
//

import CaloriesFoundation
import SwiftData
import Foundation

extension MealPlanEntry {
    // MARK: - Meal Selections

    func setMealSelections(_ selections: [MealSelection]) {
        mealSelections = selections.map { StoredMealSelection(from: $0) }
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
        guard components.count == 3 else { return nil }

        let personRawValue = components[0]
        let dateRawValue = components[1]
        let mealTypeRawValue = components[2]
        guard let person = Person(rawValue: personRawValue),
            let mealType = MealType.allCases.first(where: { $0.rawValue == mealTypeRawValue }),
            let date = PersonMealKey.formatter.date(
                from: dateRawValue.replacingOccurrences(of: "/", with: "-"))
        else {
            return nil
        }

        return PersonMealKey(person: person, dayMeal: DayMeal(mealType: mealType, date: date))
            .normalize()
    }

    private func parseMealKeyFromString(_ keyString: String) -> MealKey? {
        let components = keyString.split(
            separator: "-", maxSplits: 1, omittingEmptySubsequences: false
        ).map(String.init)
        guard components.count >= 2 else { return nil }

        let dateRawValue = components[0]
        let mealTypeRawValue = components[1]
        guard let mealType = MealType.allCases.first(where: { $0.rawValue == mealTypeRawValue }),
            let date = PersonMealKey.formatter.date(
                from: dateRawValue.replacingOccurrences(of: "/", with: "-"))
        else {
            return nil
        }

        return MealKey(dayMeal: DayMeal(mealType: mealType, date: date)).normalize()
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
