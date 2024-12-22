//
//  PlantEntry.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model public class PlantEntry {
    @Attribute(. unique) var name: String
    var timeConsumed: Date
    @Attribute(.externalStorage) var imageData: Data?

    var foodEntries: [FoodEntry]?
    var numEntries: Int {
        foodEntries?.count ?? 0
    }

    var uiImage: UIImage? {
        guard let imageData,
              let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return uiImage
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
