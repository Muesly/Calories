//
//  FoodEntry+CoreDataProperties.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//
//

import Foundation
import CoreData


extension FoodEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodEntry> {
        return NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
    }

    @NSManaged public var calories: Double
    @NSManaged public var foodDescription: String
    @NSManaged public var timeConsumed: Date?
}

extension FoodEntry : Identifiable {

}
