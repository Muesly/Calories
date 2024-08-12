//
//  ExerciseEntry.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import CoreData
import Foundation

class ExerciseEntry: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseEntry> {
        return NSFetchRequest<ExerciseEntry>(entityName: "ExerciseEntry")
    }

    @NSManaged public var exerciseDescription: String
    @NSManaged public var calories: Int
    @NSManaged public var timeExercised: Date

    convenience init(context: NSManagedObjectContext,
                     exerciseDescription: String,
                     calories: Int,
                     timeExercised: Date
    ) {
        self.init(context: context)
        self.calories = calories
        self.exerciseDescription = exerciseDescription
        self.timeExercised = timeExercised
    }
}
