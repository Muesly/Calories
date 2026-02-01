//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

import CaloriesFoundation
import ExerciseTracking
import WeightTracking
import PlantTracking
import Companion
import Charting
import FoodTracking
import MealPlanning

@main
struct CaloriesApp: App {
    let isUITesting: Bool
    let isUnitTesting: Bool
    let overriddenCurrentDate: Date?

    var healthStore: HealthStore {
        isUITesting ? HealthStoreFactory.createNull() : HealthStoreFactory.create()
    }

    var companion: Companion {
        isUITesting ? Companion.createNull() : Companion.create()
    }

    var container: ModelContainer {
        let config =
            isUITesting
            ? ModelConfiguration(url: URL(fileURLWithPath: "/dev/null"))
            : ModelConfiguration("Model")
        let container = try! ModelContainer(
            for: FoodEntry.self, PlantEntry.self, IngredientEntry.self, ExerciseEntry.self,
            RecipeEntry.self, RecipeIngredient.self, MealPlanEntry.self,
            configurations: config)

        if !isUITesting {
            migratePlantEntriesToIngredients(container: container)
        }

        return container
    }

    private func migratePlantEntriesToIngredients(container: ModelContainer) {
        let context = ModelContext(container)

        do {
            // Fetch all PlantEntry objects if they exist
            let fetchDescriptor = FetchDescriptor<PlantEntry>()
            let plantEntries = try context.fetch(fetchDescriptor)

            guard !plantEntries.isEmpty else { return }

            // Convert PlantEntry to IngredientEntry with isPlant = true
            for plant in plantEntries {
                let ingredient = IngredientEntry(
                    plant.name, imageData: plant.imageData, isPlant: true)
                context.insert(ingredient)
            }

            // Delete all PlantEntry objects
            for plant in plantEntries {
                context.delete(plant)
            }

            try context.save()
        } catch {
            print("Migration error: \(error)")
        }
    }

    init() {
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        self.isUnitTesting = ProcessInfo.processInfo.arguments.contains("UNIT_TESTING")

        if let overriddenDateStr = ProcessInfo.processInfo.environment["CURRENT_DATE"] {
            let df = DateFormatter()
            df.dateFormat = "dd/MM/yyyy"
            overriddenCurrentDate = df.date(from: overriddenDateStr)!
        } else {
            overriddenCurrentDate = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if !isUnitTesting {
                CaloriesView(
                    healthStore: healthStore,
                    companion: companion,
                    overriddenCurrentDate: overriddenCurrentDate
                )
                .modelContainer(container)
            }
        }
    }
}

extension EnvironmentValues {
    @Entry var currentDate = Date()
}
