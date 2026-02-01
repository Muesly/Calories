//
//  PersonMealKey.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation
import CaloriesFoundation

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

    static var formatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]  // Just date, no time: "2026-03-05"
        return formatter
    }
}
