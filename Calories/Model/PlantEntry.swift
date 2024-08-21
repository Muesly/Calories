//
//  PlantEntry.swift
//  Calories
//
//  Created by Tony Short on 21/08/2024.
//

import Foundation
import CoreData

class PlantEntry: NSManagedObject, Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlantEntry> {
        return NSFetchRequest<PlantEntry>(entityName: "PlantEntry")
    }

    @NSManaged public var name: String
    @NSManaged public var timeConsumed: Date?

    convenience init(context: NSManagedObjectContext,
         name: String,
         timeConsumed: Date
    ) {
        self.init(context: context)
        self.name = name
        self.timeConsumed = timeConsumed
    }
}
