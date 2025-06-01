//
//  EntryModels.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//

import Foundation
import SwiftData

@Model public class FoodEntry {
    var calories: Double = 0.0
    var foodDescription: String = ""
    var timeConsumed: Date
    @Relationship public var plants: [PlantEntry]?
    public init(foodDescription: String,
                calories: Double,
                timeConsumed: Date,
                plants: [PlantEntry] = []) {
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

    func insert(into modelContext: ModelContext) -> FoodEntry {
        modelContext.insert(self)
        return self
    }
}

@Model public class PlantEntry {
    @Attribute(.unique) var name: String
    #Index<PlantEntry>([\.name])
    var timeConsumed: Date
    @Attribute(.externalStorage) var imageData: Data?

    @Relationship(inverse: \FoodEntry.plants) public var foodEntries: [FoodEntry]?
    var numEntries: Int {
        foodEntries?.count ?? 0
    }

    public init(_ name: String, timeConsumed: Date = Date(), imageData: Data? = nil) {
        self.name = name
        self.timeConsumed = timeConsumed
        self.imageData = imageData
    }
}

extension PlantEntry: Equatable {
    public static func == (lhs: PlantEntry, rhs: PlantEntry) -> Bool {
        lhs.name == rhs.name
    }

    @discardableResult
    func insert(into modelContext: ModelContext) -> PlantEntry {
        modelContext.insert(self)
        return self
    }
} 
