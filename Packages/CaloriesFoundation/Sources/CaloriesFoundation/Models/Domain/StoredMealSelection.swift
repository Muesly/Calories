//
//  StoredMealSelection.swift
//  MealPlanning
//
//  Created by Tony Short on 01/02/2026.
//

import Foundation

// MARK: - Codable structs for storage

public struct StoredMealSelection: Codable {
    public var person: String
    public var dateTimestamp: Double
    public var mealType: String
    public var isSelected: Bool
    public var recipeName: String?

    public init(from selection: MealSelection) {
        self.person = selection.person.rawValue
        self.dateTimestamp = selection.dayMeal.date.timeIntervalSince1970
        self.mealType = selection.dayMeal.mealType.rawValue
        self.isSelected = selection.isSelected
        self.recipeName = selection.recipe?.name
    }

    public func toMealSelection(recipes: [RecipeEntry]) -> MealSelection {
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

public struct StoredFoodToUseUp: Codable {
    public var id: String
    public var name: String
    public var isFullMeal: Bool
    public var isFrozen: Bool

    public init(from food: FoodToUseUp) {
        self.id = food.id.uuidString
        self.name = food.name
        self.isFullMeal = food.isFullMeal
        self.isFrozen = food.isFrozen
    }

    public func toFoodToUseUp() -> FoodToUseUp {
        FoodToUseUp(name: name, isFullMeal: isFullMeal, isFrozen: isFrozen)
    }
}
