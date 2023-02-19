//
//  AddExerciseViewModel.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

class AddExerciseViewModel {
    let healthStore: HealthStore

    init(healthStore: HealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func addExercise(exerciseDescription: String, calories: Int, timeExercised: Date) async throws {
        let exerciseEntry = ExerciseEntry(exerciseDescription: exerciseDescription,
                                          calories: calories,
                                          timeExercised: timeExercised)
        try await healthStore.authorize()
        try await healthStore.addExerciseEntry(exerciseEntry)
    }

    static func shouldClearFields(phase: ScenePhase, date: Date) -> Bool {
        if phase == .active {
            guard let dayDiff = Calendar.current.dateComponents([.day], from: date, to: Date()).day else {
                return false
            }
            return dayDiff > 0 ? true : false
        }
        return false
    }
}
