//
//  FoodEntry.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//

import Foundation
import SwiftData

@Model public class FoodEntry {
    public var calories: Double = 0.0
    public var foodDescription: String = ""
    public var timeConsumed: Date
    @Relationship public var ingredients: [IngredientEntry]?

    public init(
        foodDescription: String,
        calories: Double,
        timeConsumed: Date,
        ingredients: [IngredientEntry] = []
    ) {
        self.foodDescription = foodDescription
        self.calories = calories
        self.timeConsumed = timeConsumed
        self.ingredients = ingredients
    }

    public var plants: [IngredientEntry]? {
        ingredients?.filter { $0.isPlant }
    }
}

public extension FoodEntry {
    static var mostRecent: SortDescriptor<FoodEntry> {
        SortDescriptor(\.timeConsumed, order: .reverse)
    }

    func insert(into modelContext: ModelContext) -> FoodEntry {
        modelContext.insert(self)
        return self
    }
}
