//
//  FoodToUseUp.swift
//  Calories
//
//  Created by Tony Short on 13/01/2026.
//

import Foundation

public struct FoodToUseUp: Identifiable {
    public let id: UUID
    public var name: String
    public var isFullMeal: Bool  // true = complete meal (🍲), false = ingredient (🥩)
    public var isFrozen: Bool  // needs thawing consideration

    public init(name: String = "", isFullMeal: Bool = false, isFrozen: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isFullMeal = isFullMeal
        self.isFrozen = isFrozen
    }

    public var typeEmoji: String {
        isFullMeal ? "🍲" : "🥩"
    }
}
