//
//  Meal.swift
//  Calories
//
//  Created by Tony Short on 02/03/2023.
//

import Foundation

public class Meal: Identifiable, Equatable {
    public let mealType: MealType
    public var foodEntries = [FoodEntry]()

    public init(mealType: MealType, foodEntries: [FoodEntry]) {
        self.mealType = mealType
        self.foodEntries = foodEntries
    }

    public var summary: String {
        let mealCalories = Int(foodEntries.reduce(0) { $0 + $1.calories })
        return "\(mealType.rawValue) (\(mealCalories) cals)"
    }

    public static func == (lhs: Meal, rhs: Meal) -> Bool {
        return (lhs.mealType == rhs.mealType) && (lhs.foodEntries == rhs.foodEntries)
    }
}
