//
//  IngredientEntry.swift
//  Calories
//
//  Created by Tony Short on 24/12/2025.
//

import UIKit
import SwiftData

@Model public class IngredientEntry {
    @Attribute(.unique) public var name: String
    @Attribute(.externalStorage) public var imageData: Data?
    @Relationship(inverse: \FoodEntry.ingredients) public var foodEntries: [FoodEntry]?
    public var isPlant: Bool = false

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

    public convenience init(_ name: String, imageName: String, isPlant: Bool = true) {
        self.init(
            name,
            imageData: UIImage(named: imageName)?.jpegData(compressionQuality: 0.9),
            isPlant: isPlant)
    }

    public var uiImage: UIImage? {
        guard let imageData,
            let uiImage = UIImage(data: imageData)
        else {
            return nil
        }
        return uiImage
    }
}

public extension IngredientEntry {
    static func addPreviewIngredients(context: ModelContext) -> [IngredientEntry] {
        let ingredients = [
            IngredientEntry("Corn", isPlant: true),
            IngredientEntry("Rice", isPlant: true),
            IngredientEntry("Broccoli", isPlant: true),
            IngredientEntry("Unidentified"),
            IngredientEntry("Corn 2", isPlant: true),
        ]
        for ingredient in ingredients { context.insert(ingredient) }
        return ingredients
    }
}
