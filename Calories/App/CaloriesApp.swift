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
            RecipeEntry.self, RecipeIngredient.self,
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

class StubbedHealthStore: HealthStore {
    var initialWeight = 200
    var caloriesConsumedReads = 0
    var weightBetweenDatesIndex = 0
    var weightAllDataPoints: [(Date, Int)] = [
        (Date().startOfWeek.addingTimeInterval(-(7 * 86400) - 1), 200),
        (Date().startOfWeek.addingTimeInterval(-1), 199),
        (Date(), 198),
    ]

    func authorize() async throws {}

    func caloriesConsumed(date: Date) async throws -> Int {
        caloriesConsumedReads += 1
        if caloriesConsumedReads > 100 {
            return 0
        } else {
            return 1800
        }
    }

    func bmr(date: Date) async throws -> Int {
        1500
    }

    func exercise(date: Date) async throws -> Int {
        600
    }

    private func waitForResult() async {
        let _ = await withCheckedContinuation { continuation in
            Task.detached {
                try? await Task.sleep(for: .seconds(0.01))
                return continuation.resume()
            }
        }
    }

    func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        await waitForResult()
        guard weightBetweenDatesIndex < weightAllDataPoints.count else { return nil }
        // The concrete function returns most recent first then goes back, so we reverse here.
        let weight = weightAllDataPoints.reversed()[weightBetweenDatesIndex]
        weightBetweenDatesIndex += 1
        return weight.1
    }

    func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)] {
        []
    }

    func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool)
        async throws -> [(Date, Int)]
    {
        []
    }

    func bmrBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(
        Date, Int
    )] {
        []
    }

    func activeBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(
        Date, Int
    )] {
        []
    }

    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)] {
        []
    }

    func weeklyWeightChange() async throws -> Int {
        0
    }

    func monthlyWeightChange() async throws -> Int {
        0
    }

    func addFoodEntry(_ foodEntry: FoodEntry) async throws {

    }

    func deleteFoodEntry(_ foodEntry: FoodEntry) async throws {

    }

    func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws {

    }

    func addWeightEntry(_ weightEntry: WeightEntry) async throws {
        weightAllDataPoints.append((weightEntry.timeRecorded, weightEntry.weight))
        weightBetweenDatesIndex = 0
    }
}
