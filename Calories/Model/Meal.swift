//
//  Meal.swift
//  Calories
//
//  Created by Tony Short on 02/03/2023.
//

import Foundation

class Meal: Identifiable, Equatable {
    let mealType: MealType
    var foodEntries = [FoodEntry]()

    init(mealType: MealType, foodEntries: [FoodEntry]) {
        self.mealType = mealType
        self.foodEntries = foodEntries
    }

    var summary: String {
        let mealCalories = Int(foodEntries.reduce(0) { $0 + $1.calories })
        return "\(mealType.rawValue) (\(mealCalories) cals)"
    }

    static func == (lhs: Meal, rhs: Meal) -> Bool {
        return (lhs.mealType == rhs.mealType) && (lhs.foodEntries == rhs.foodEntries)
    }
}
