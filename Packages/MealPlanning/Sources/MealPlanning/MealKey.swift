//
//  MealKey.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation

/// Type-safe key for meal-level data (shared across people)
struct MealKey: Hashable, Comparable {
    let dayMeal: DayMeal

    func normalize() -> MealKey {
        MealKey(
            dayMeal: DayMeal(
                mealType: dayMeal.mealType,
                date: Calendar.current.startOfDay(for: dayMeal.date))
        )
    }

    static func < (lhs: MealKey, rhs: MealKey) -> Bool {
        return lhs.dayMeal < rhs.dayMeal
    }
}
