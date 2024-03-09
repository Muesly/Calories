//
//  Plant.swift
//  Calories
//
//  Created by Tony Short on 14/01/2024.
//

import Foundation
import CoreData

class Plant: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Plant> {
        return NSFetchRequest<Plant>(entityName: "Plant")
    }

    @NSManaged public var points: Float
    @NSManaged public var name: String

    convenience init(context: NSManagedObjectContext,
                     name: String,
                     points: Float) {
        self.init(context: context)
        self.name = name
        self.points = points
    }
}

extension Plant : Identifiable {

}
