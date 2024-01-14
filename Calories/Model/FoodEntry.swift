//
//  FoodEntry+CoreDataProperties.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//
//

import Foundation
import CoreData


class FoodEntry: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodEntry> {
        return NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
    }

    @NSManaged public var calories: Double
    @NSManaged public var foodDescription: String
    @NSManaged public var timeConsumed: Date?

    convenience init(context: NSManagedObjectContext,
         foodDescription: String,
         calories: Double,
         timeConsumed: Date
    ) {
        self.init(context: context)
        self.calories = calories
        self.foodDescription = foodDescription
        self.timeConsumed = timeConsumed
    }
}

extension FoodEntry : Identifiable {

}
