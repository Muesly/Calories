//
//  MealPickerEngine.swift
//  Calories
//
//  Created by Tony Short on 17/12/2025.
//

import Foundation

struct MealPickerEngine {
    let recipes: [RecipeEntry]

    /// Picks a recipe for the given meal type, considering variety across the meal plan
    /// - Parameters:
    ///   - dayMeal: The date and type of meal to pick for
    ///   - usedRecipes: Previously selected recipes with their dates and meal types
    /// - Returns: A recipe suitable for this meal, avoiding repetition except dinner-to-lunch across days
    func pickRecipe(
        dayMeal: DayMeal,
        usedRecipes: [(dayMeal: DayMeal, recipe: RecipeEntry)]
    ) -> RecipeEntry? {
        // Filter recipes to exclude those already used, with dinner-to-lunch exception
        let availableRecipes = recipes.filter { recipe in
            isRecipeAvailable(
                recipe,
                forDayMeal: dayMeal,
                usedRecipes: usedRecipes
            )
        }

        // Weight recipes based on meal type suitability
        return availableRecipes.flatMap { recipe in
            Array(repeating: recipe, count: recipe.suitability(for: dayMeal.mealType).weight)
        }.randomElement()
    }

    /// Determines if a recipe can be used for a given meal
    private func isRecipeAvailable(
        _ recipe: RecipeEntry,
        forDayMeal dayMeal: DayMeal,
        usedRecipes: [(dayMeal: DayMeal, recipe: RecipeEntry)]
    ) -> Bool {
        // Check if this recipe has been used
        let previousUses = usedRecipes.filter { $0.recipe == recipe }

        if previousUses.isEmpty {
            return true  // Recipe hasn't been used yet
        }

        // Recipe has been used - check if it's allowed
        // Exception: dinner yesterday can be reused for lunch today
        if dayMeal.mealType == .lunch {
            let calendar = Calendar.current
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: dayMeal.date) {
                // Check if this recipe was used for dinner yesterday
                let wasDinnerYesterday = previousUses.contains { use in
                    use.dayMeal.mealType == .dinner
                        && calendar.isDate(use.dayMeal.date, inSameDayAs: yesterday)
                }
                if wasDinnerYesterday {
                    return true  // Allow dinner-to-lunch reuse
                }
            }
        }

        return false  // Recipe already used, no exception applies
    }
}

extension RecipeEntry {
    fileprivate func suitability(for mealType: MealType) -> MealSuitability {
        switch mealType {
        case .breakfast: breakfastSuitability
        case .lunch: lunchSuitability
        case .dinner: dinnerSuitability
        default: .never
        }
    }
}

extension MealSuitability {
    fileprivate var weight: Int {
        switch self {
        case .never: 0
        case .sometimes: 1
        case .always: 3
        }
    }
}
