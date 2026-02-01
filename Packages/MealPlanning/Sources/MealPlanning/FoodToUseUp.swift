//
//  FoodToUseUp.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation
import CaloriesFoundation

struct FoodToUseUp: Identifiable {
    let id: UUID
    var name: String
    var isFullMeal: Bool  // true = complete meal (🍲), false = ingredient (🥩)
    var isFrozen: Bool  // needs thawing consideration

    init(name: String = "", isFullMeal: Bool = false, isFrozen: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isFullMeal = isFullMeal
        self.isFrozen = isFrozen
    }

    var typeEmoji: String {
        isFullMeal ? "🍲" : "🥩"
    }
}
