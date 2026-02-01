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
    @Attribute(.externalStorage) var imageData: Data?

    public init(_ name: String, imageData: Data? = nil) {
        self.name = name
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
