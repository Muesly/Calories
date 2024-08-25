//
//  FoodEntry.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//
//

import Foundation
import SwiftData

@Model public class FoodEntry {
    var calories: Double = 0.0
    var foodDescription: String = ""
    var timeConsumed: Date
    @Relationship(inverse: \PlantEntry.foodEntries) var plants: [PlantEntry]?
    public init(foodDescription: String,
                calories: Double,
                timeConsumed: Date,
                plants: [PlantEntry]) {
        self.foodDescription = foodDescription
        self.calories = calories
        self.timeConsumed = timeConsumed
        self.plants = plants
    }
}

extension FoodEntry {
    static var mostRecent: SortDescriptor<FoodEntry> {
        SortDescriptor(\.timeConsumed, order: .reverse)
    }
}
