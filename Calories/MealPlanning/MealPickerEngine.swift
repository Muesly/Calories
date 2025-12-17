//
//  MealPickerEngine.swift
//  Calories
//
//  Created by Tony Short on 17/12/2025.
//

import Foundation

struct MealPickerEngine {
    let recipes: [RecipeEntry]

    func pickRecipe(mealType: MealType) -> RecipeEntry? {
        recipes.flatMap { recipe in
            Array(repeating: recipe, count: recipe.suitability(for: mealType).weight)
        }.randomElement()
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
        case .some: 1
        case .always: 3
        }
    }
}
