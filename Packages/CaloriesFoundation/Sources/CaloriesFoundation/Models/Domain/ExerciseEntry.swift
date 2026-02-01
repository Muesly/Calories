//
//  ExerciseEntry.swift
//  Calories
//
//  Created by Tony Short on 25/08/2024.
//
//

import Foundation
import SwiftData

@Model public class ExerciseEntry {
    var calories: Int32
    var exerciseDescription: String
    var timeExercised: Date
    public init(
        exerciseDescription: String,
        calories: Int,
        timeExercised: Date
    ) {
        self.exerciseDescription = exerciseDescription
        self.calories = Int32(calories)
        self.timeExercised = timeExercised
    }
}

extension ExerciseEntry {
    static var mostRecent: SortDescriptor<ExerciseEntry> {
        SortDescriptor(\.timeExercised, order: .reverse)
    }

    func insert(into modelContext: ModelContext) -> ExerciseEntry {
        modelContext.insert(self)
        return self
    }
}
