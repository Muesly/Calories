//
//  IngredientEntry.swift
//  Calories
//
//  Created by Tony Short on 24/12/2025.
//

import Foundation
import SwiftData

@Model public class IngredientEntry {
    @Attribute(.unique) var name: String
    #Index<IngredientEntry>([\.name])
    @Attribute(.externalStorage) var imageData: Data?
    var isPlant: Bool = false

    public init(_ name: String, imageData: Data? = nil, isPlant: Bool = false) {
        self.name = name
        self.imageData = imageData
        self.isPlant = isPlant
    }
}

extension IngredientEntry: Equatable {
    public static func == (lhs: IngredientEntry, rhs: IngredientEntry) -> Bool {
        lhs.name == rhs.name
    }

    @discardableResult
    func insert(into modelContext: ModelContext) -> IngredientEntry {
        modelContext.insert(self)
        return self
    }
}

extension IngredientEntry {
    static func addPreviewIngredients(context: ModelContext) -> [IngredientEntry] {
        let ingredients = [
            IngredientEntry("Corn", imageName: "Corn"),
            IngredientEntry("Rice", imageName: "Rice"),
            IngredientEntry("Broccoli", imageName: "Broccoli"),
            IngredientEntry("Unidentified"),
            IngredientEntry("Corn 2", imageName: "Corn"),
        ]
        for ingredient in ingredients { context.insert(ingredient) }
        return ingredients
    }
}
