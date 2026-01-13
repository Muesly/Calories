//
//  MealSelection.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation

struct MealSelection {
    var person: Person
    var dayMeal: DayMeal
    var isSelected: Bool
    var recipe: RecipeEntry?

    var id: String {
        "\(person.rawValue)-\(dayMeal.keyString)"
    }
}
