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
    #Index<ExerciseEntry>([])
    var calories: Int32 = 0.0
    var exerciseDescription: String
    var timeExercised: Date
    public init(exerciseDescription: String, timeExercised: Date) {
        self.exerciseDescription = exerciseDescription
        self.timeExercised = timeExercised

    }
    

#warning("Index on ExerciseEntry:timeExercised is unsupported in SwiftData.")

}
