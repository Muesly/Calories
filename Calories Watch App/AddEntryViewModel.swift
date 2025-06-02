//
//  AddEntryViewModel.swift
//  Calories Watch App
//
//  Created by Tony Short on 19/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

class AddEntryViewModel {
    let healthStore: HealthStore

    init(healthStore: HealthStore) {
        self.healthStore = healthStore
    }

    func addFood(calories: Int, timeConsumed: Date) async throws {
        let foodEntry = FoodEntry(
            calories: Double(calories),
            foodDescription: "",
            timeConsumed: timeConsumed)
        try await healthStore.authorize()
        try await healthStore.addFoodEntry(foodEntry)
    }

    func addExercise(calories: Int, timeExercised: Date) async throws {
        let exerciseEntry = ExerciseEntry(
            exerciseDescription: "",
            calories: calories,
            timeExercised: timeExercised)
        try await healthStore.authorize()
        try await healthStore.addExerciseEntry(exerciseEntry)
    }
}
