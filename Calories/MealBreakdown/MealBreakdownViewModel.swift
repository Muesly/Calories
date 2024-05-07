//
//  MealBreakdownViewModel.swift
//  Calories
//
//  Created by Tony Short on 05/03/2023.
//

import Foundation
import HealthKit
import SwiftUI

class MealBreakdownViewModel: ObservableObject {
    let healthStore: HealthStore
    @Published var caloriesPerMealType: [(Double, Color)] = []

    init(healthStore: HealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    @MainActor
    func getCaloriesPerMealType() async {
        let toDate = Date()
        let fromDate = toDate.addingTimeInterval(-secsPerWeek * 8)
        do {
            let consumptionDataPoints = try await healthStore.caloriesConsumedAllDataPoints(fromDate: fromDate, toDate: toDate, applyModifier: true)
            var meals = [MealType: Int]()
            var totalCalories = 0
            consumptionDataPoints.forEach { dataPoint in
                let timeConsumed = dataPoint.0
                let calories = dataPoint.1
                totalCalories += calories
                let mealType = MealType.mealTypeForDate(timeConsumed)
                if let existingCalories = meals[mealType] {
                    meals[mealType] = existingCalories + calories
                } else {
                    meals[mealType] = calories
                }
            }
            self.caloriesPerMealType = meals.map { (Double($0.value) / Double(totalCalories), $0.key.mealTypeColor()) }
        } catch {
            print("Failed to fetch calories per meal type")
        }
    }
}
