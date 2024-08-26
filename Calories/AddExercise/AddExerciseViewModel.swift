//
//  AddExerciseViewModel.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import Foundation
import HealthKit
import SwiftData
import SwiftUI

@Observable
class AddExerciseViewModel {
    let modelContext: ModelContext
    let healthStore: HealthStore
    var suggestions: [Suggestion] = []
    
    init(healthStore: HealthStore,
         modelContext: ModelContext) {
        self.healthStore = healthStore
        self.modelContext = modelContext
    }
    
    func addExercise(exerciseDescription: String, calories: Int, timeExercised: Date) async throws {
        try await healthStore.authorize()
        let exerciseEntry = ExerciseEntry(exerciseDescription: exerciseDescription,
                                          calories: calories,
                                          timeExercised: timeExercised).insert(into: modelContext)
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
    
    func fetchSuggestions(searchText: String = "") {
        var results = modelContext.exerciseResults()
        if !searchText.isEmpty { // Show fuzzy matched strings for this search text
            results = results.filter { exerciseEntry in
                return exerciseEntry.exerciseDescription.fuzzyMatch(searchText)
            }
        }
        let orderedSet = NSOrderedSet(array: results.map { Suggestion(name: $0.exerciseDescription) })
        suggestions = orderedSet.map { $0 as! Suggestion }
    }
}
