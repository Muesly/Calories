//
//  PlantEntry.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//
//

import Foundation
import SwiftData

@Model public class PlantEntry {
    var name: String
    var timeConsumed: Date
    var foodEntries: [FoodEntry]?
    public init(name: String, timeConsumed: Date) {
        self.name = name
        self.timeConsumed = timeConsumed
    }
}
