//
//  FoodEntry+CoreDataClass.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//
//

import Foundation
import CoreData


public class FoodEntry: NSManagedObject {
    convenience init(context: ManagedContext, foodDescription: String, calories: Double, timeConsumed: Date) {
        self.init(context: context as! NSManagedObjectContext)
        self.foodDescription = foodDescription
        self.calories = calories
        self.timeConsumed = timeConsumed
    }
}
