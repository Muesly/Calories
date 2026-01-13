//
//  PersonMealKey.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation

enum Person: String, CaseIterable {
    case tony = "Tony"
    case karen = "Karen"
}

/// Type-safe key for person-specific meal data
struct PersonMealKey: Hashable {
    let person: Person
    let dayMeal: DayMeal

    func normalize() -> PersonMealKey {
        PersonMealKey(
            person: person,
            dayMeal: DayMeal(
                mealType: self.dayMeal.mealType,
                date: Calendar.current.startOfDay(for: self.dayMeal.date))
        )
    }

    var keyString: String {
        "\(person.rawValue)-\(dayMeal.keyString)"
    }
}
