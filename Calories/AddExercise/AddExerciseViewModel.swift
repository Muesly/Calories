//
//  AddExerciseViewModel.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import CoreData
import Foundation
import HealthKit
import SwiftUI

@Observable
class AddExerciseViewModel {
    let container: NSPersistentContainer
    let healthStore: HealthStore
    var suggestions: [Suggestion] = []
    
    init(healthStore: HealthStore,
         container: NSPersistentContainer = PersistenceController.shared.container) {
        self.healthStore = healthStore
        self.container = container
    }
    
    func addExercise(exerciseDescription: String, calories: Int, timeExercised: Date) async throws {
        try await healthStore.authorize()
        let exerciseEntry = ExerciseEntry(context: container.viewContext,
                                          exerciseDescription: exerciseDescription,
                                          calories: calories,
                                          timeExercised: timeExercised)
        try await healthStore.addExerciseEntry(exerciseEntry)
        try container.viewContext.save()
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
        let request = ExerciseEntry.fetchRequest()

        if searchText.isEmpty { // Show list of all previous exercises
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseEntry.timeExercised, ascending: false)]
            guard let results: [ExerciseEntry] = (try? container.viewContext.fetch(request)) else {
                suggestions = []
                return
            }
            let orderedSet = NSOrderedSet(array: results.map { Suggestion(name: $0.exerciseDescription) })
            suggestions = orderedSet.map { $0 as! Suggestion }
        } else {    // Show fuzzy matched strings for this search text
            request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseEntry.timeExercised, ascending: false)]
            guard let results: [ExerciseEntry] = (try? container.viewContext.fetch(request)) else {
                suggestions = []
                return
            }
            let filteredResults = results.filter { exerciseEntry in
                return exerciseEntry.exerciseDescription.fuzzyMatch(searchText)
            }
            let orderedSet = NSOrderedSet(array: filteredResults.map { Suggestion(name: $0.exerciseDescription) })
            suggestions = orderedSet.map { $0 as! Suggestion }
        }
    }
}
