//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import CoreData
import SwiftUI

@main
struct CaloriesApp: App {
    var body: some Scene {
        WindowGroup {
            CaloriesView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}

