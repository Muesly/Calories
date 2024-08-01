//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import HealthKit
import SwiftUI

@main
struct CaloriesApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            print("UI testing")
        }
    }
    var body: some Scene {
        WindowGroup {
            CaloriesView()
            //DataView()
        }
    }
}
