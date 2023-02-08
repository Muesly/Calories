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
    let container = PersistenceController.shared.container

    var body: some Scene {
        WindowGroup {
            CaloriesView(viewModel: CaloriesViewModel(container: container))
                .environment(\.managedObjectContext, container.viewContext)
        }
    }
}

