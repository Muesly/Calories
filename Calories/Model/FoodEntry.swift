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
    #Index<FoodEntry>([])
    var calories: Double = 0.0
    var foodDescription: String = ""
    var timeConsumed: Date
    @Relationship(inverse: \PlantEntry.foodEntries) var plants: [PlantEntry]?
    public init(timeConsumed: Date) {
        self.timeConsumed = timeConsumed

    }
    

#warning("Index on FoodEntry:timeConsumed is unsupported in SwiftData.")
#warning("The property \"ordered\" on FoodEntry:plants is unsupported in SwiftData.")

}
