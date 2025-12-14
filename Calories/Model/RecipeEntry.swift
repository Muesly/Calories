//
//  Recipe.swift
//  Calories
//
//  Created by Tony Short on 14/12/2024.
//

import Foundation
import SwiftData

@Model public class RecipeEntry {
    @Attribute(.unique) var name: String

    public init(name: String) {
        self.name = name
    }
}

extension RecipeEntry: Equatable {
    public static func == (lhs: RecipeEntry, rhs: RecipeEntry) -> Bool {
        lhs.name == rhs.name
    }

    static var byName: SortDescriptor<RecipeEntry> {
        SortDescriptor(\.name, order: .forward)
    }

    @discardableResult
    func insert(into modelContext: ModelContext) -> RecipeEntry {
        modelContext.insert(self)
        return self
    }

    static func seedRecipes(into modelContext: ModelContext) {
        let descriptor = FetchDescriptor<RecipeEntry>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let recipeNames = [
            "Scrambled Eggs on Toast",
            "Greek Yoghurt & Berries",
            "Chicken Glow Bowl",
            "Tuna Salad",
            "Greek Salad",
            "Roasted Feta & Vegetables",
            "Tofu Thai Green Curry",
            "Moroccan Lamb",
        ]

        for name in recipeNames {
            let recipe = RecipeEntry(name: name)
            recipe.insert(into: modelContext)
        }
    }
}
