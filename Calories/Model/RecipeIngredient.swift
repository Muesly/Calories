//
//  RecipeIngredient.swift
//  Calories
//
//  Created by Tony Short on 24/12/2025.
//

import Foundation
import SwiftData

public enum IngredientUnit: String, Codable, CaseIterable {
    case milliliters = "ml"
    case liters = "l"
    case grams = "g"
    case kilograms = "kg"
    case cups = "cups"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"
    case ounces = "oz"
    case pounds = "lb"
    case pieces = "pcs"

    var displayName: String {
        self.rawValue
    }
}

@Model public class RecipeIngredient {
    var quantity: Double
    var unit: IngredientUnit
    @Relationship public var ingredient: IngredientEntry?
    @Relationship(deleteRule: .cascade) public var recipe: RecipeEntry?

    public init(
        quantity: Double,
        unit: IngredientUnit,
        ingredient: IngredientEntry? = nil,
        recipe: RecipeEntry? = nil
    ) {
        self.quantity = quantity
        self.unit = unit
        self.ingredient = ingredient
        self.recipe = recipe
    }
}

extension RecipeIngredient: Equatable {
    public static func == (lhs: RecipeIngredient, rhs: RecipeIngredient) -> Bool {
        lhs.quantity == rhs.quantity && lhs.unit == rhs.unit && lhs.ingredient == rhs.ingredient
    }

    @discardableResult
    func insert(into modelContext: ModelContext) -> RecipeIngredient {
        modelContext.insert(self)
        return self
    }
}

extension RecipeIngredient {
    var displayString: String {
        let quantityStr = String(format: "%.2g", quantity).replacingOccurrences(of: ",", with: ".")
        return "\(quantityStr) \(unit.displayName) \(ingredient?.name ?? "Unknown")"
    }
}
