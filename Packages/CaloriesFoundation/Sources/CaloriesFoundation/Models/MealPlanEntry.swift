//
//  MealPlanEntry.swift
//  Calories
//
//  Created by Tony Short on 29/12/2025.
//

import Foundation
import SwiftData

// MARK: - MealPlanEntry Model

@Model public class MealPlanEntry {
    @Attribute(.unique) public var weekStartDate: Date

    // Stored as JSON-encoded data
    public var mealSelectionsData: Data?
    public var mealReasonsData: Data?
    public var quickMealsData: Data?
    public var pinnedMealsData: Data?
    public var foodToUseUpData: Data?

    public init(weekStartDate: Date) {
        self.weekStartDate = weekStartDate
    }

    public var mealSelections: [StoredMealSelection] {
        get {
            guard let data = mealSelectionsData else { return [] }
            return (try? JSONDecoder().decode([StoredMealSelection].self, from: data)) ?? []
        }
        set {
            mealSelectionsData = try? JSONEncoder().encode(newValue)
        }
    }

    public func getMealSelections(recipes: [RecipeEntry]) -> [MealSelection] {
        mealSelections.map { $0.toMealSelection(recipes: recipes) }
    }
}
