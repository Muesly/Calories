//
//  CaloriesWatchApp.swift
//  CaloriesWatch Watch App
//
//  Created by Tony Short on 15/02/2023.
//

import SwiftUI

@main
struct CaloriesWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                TwoDayChartView()
                WeeklyProgressView()
                Text("Page Three")
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
}
