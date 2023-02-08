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
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CaloriesView(viewModel: CaloriesViewModel(container: persistenceController.container))
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

