//
//  MealSelection.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation

public struct MealSelection {
    public var person: Person
    public var dayMeal: DayMeal
    public var isSelected: Bool
    public var recipe: RecipeEntry?

    public var id: String {
        "\(person.rawValue)-\(dayMeal.keyString)"
    }

    public init(person: Person, dayMeal: DayMeal, isSelected: Bool, recipe: RecipeEntry? = nil) {
        self.person = person
        self.dayMeal = dayMeal
        self.isSelected = isSelected
        self.recipe = recipe
    }
}

public enum Person: String, CaseIterable {
    case tony = "Tony"
    case karen = "Karen"
}
