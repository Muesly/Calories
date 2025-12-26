//
//  Recipe.swift
//  Calories
//
//  Created by Tony Short on 14/12/2024.
//

import Foundation
import SwiftData

public enum MealSuitability: Int, Codable {
    case never
    case some
    case always
}

@Model public class RecipeEntry {
    @Attribute(.unique) var name: String
    private var breakfastSuitabilityRaw: Int
    private var lunchSuitabilityRaw: Int
    private var dinnerSuitabilityRaw: Int

    var breakfastSuitability: MealSuitability {
        get { MealSuitability(rawValue: breakfastSuitabilityRaw) ?? .never }
        set { breakfastSuitabilityRaw = newValue.rawValue }
    }

    var lunchSuitability: MealSuitability {
        get { MealSuitability(rawValue: lunchSuitabilityRaw) ?? .never }
        set { lunchSuitabilityRaw = newValue.rawValue }
    }

    var dinnerSuitability: MealSuitability {
        get { MealSuitability(rawValue: dinnerSuitabilityRaw) ?? .never }
        set { dinnerSuitabilityRaw = newValue.rawValue }
    }

    public init(
        name: String,
        breakfastSuitability: MealSuitability = .never,
        lunchSuitability: MealSuitability = .never,
        dinnerSuitability: MealSuitability = .never
    ) {
        self.name = name
        self.breakfastSuitabilityRaw = breakfastSuitability.rawValue
        self.lunchSuitabilityRaw = lunchSuitability.rawValue
        self.dinnerSuitabilityRaw = dinnerSuitability.rawValue
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

        let recipes: [RecipeEntry] = [
            .init(
                name: "Scrambled Eggs on Toast",
                breakfastSuitability: .always,
                lunchSuitability: .some,
                dinnerSuitability: .some),
            .init(
                name: "Greek Yoghurt & Berries",
                breakfastSuitability: .always,
                lunchSuitability: .never,
                dinnerSuitability: .never),
            .init(
                name: "Chicken Glow Bowl",
                breakfastSuitability: .never,
                lunchSuitability: .always,
                dinnerSuitability: .some),
            .init(
                name: "Tuna Salad",
                breakfastSuitability: .never,
                lunchSuitability: .always,
                dinnerSuitability: .some),
            .init(
                name: "Greek Salad",
                breakfastSuitability: .never,
                lunchSuitability: .always,
                dinnerSuitability: .some),
            .init(
                name: "Roasted Feta & Vegetables",
                breakfastSuitability: .never,
                lunchSuitability: .some,
                dinnerSuitability: .always),
            .init(
                name: "Tofu Thai Green Curry",
                breakfastSuitability: .never,
                lunchSuitability: .some,
                dinnerSuitability: .always),
            .init(
                name: "Moroccan Lamb",
                breakfastSuitability: .never,
                lunchSuitability: .some,
                dinnerSuitability: .always),
        ]

        for recipe in recipes {
            recipe.insert(into: modelContext)
        }
    }
}
