//
//  MealPickerEngine.swift
//  Calories
//
//  Created by Tony Short on 17/12/2025.
//

import Foundation

struct MealPickerEngine {
    let recipes: [RecipeEntry]
    func pickRecipe() -> RecipeEntry? {
        recipes.randomElement()
    }
}
