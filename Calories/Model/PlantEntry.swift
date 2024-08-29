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
    @Attribute(. unique) var name: String
    var timeConsumed: Date
    var foodEntries: [FoodEntry]?
    var numEntries: Int {
        foodEntries?.count ?? 0
    }
    public init(_ name: String, timeConsumed: Date = Date()) {
        self.name = name
        self.timeConsumed = timeConsumed
    }
}

extension PlantEntry: Equatable {
    public static func == (lhs: PlantEntry, rhs: PlantEntry) -> Bool {
        lhs.name == rhs.name
    }
}
