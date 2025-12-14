//
//  PlantEntry.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//

import Foundation
import SwiftData

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
