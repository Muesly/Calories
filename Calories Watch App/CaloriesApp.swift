//
//  CaloriesApp.swift
//  Calories Watch App
//
//  Created by Tony Short on 15/02/2023.
//

import SwiftUI

@main
struct Calories_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                TwoDayChartView()
                WeeklyProgressView()
                AddEntryView()
            }
            .tabViewStyle(PageTabViewStyle())
        }
    }
}
