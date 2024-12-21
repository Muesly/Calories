//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

@main
struct CaloriesApp: App {
    let isUITesting: Bool
    let isUnitTesting: Bool

    var healthStore: HealthStore {
        isUITesting ? HealthStoreFactory.createNull() : HealthStoreFactory.create()
    }

    var companion: Companion {
        isUITesting ? Companion.createNull() : Companion.create()
    }

    var container: ModelContainer {
        let config = isUITesting ? ModelConfiguration(url: URL(fileURLWithPath: "/dev/null")) : ModelConfiguration("Model")
        return try! ModelContainer(for: FoodEntry.self, PlantEntry.self, ExerciseEntry.self, configurations: config)
    }

    init() {
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        self.isUnitTesting = ProcessInfo.processInfo.arguments.contains("UNIT_TESTING")
        requestNotificationsPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            if !isUnitTesting {
                CaloriesView(historyViewModel: HistoryViewModel(healthStore: healthStore),
                             weeklyChartViewModel: WeeklyChartViewModel(healthStore: healthStore),
                             healthStore: healthStore,
                             companion: companion)
                .modelContainer(container)
            }
        }
    }

    private func requestNotificationsPermission() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
//            if granted {
//            } else if let error = error {
//                print("Permission denied: \(error.localizedDescription)")
//            }
//        }
    }
}

class StubbedHealthStore: HealthStore {
    var initialWeight = 200
    var caloriesConsumedReads = 0

    func authorize() async throws {}
    
    func caloriesConsumed(date: Date) async throws -> Int {
        caloriesConsumedReads += 1
        if caloriesConsumedReads > 100 {
            return 0
        } else {
            return 1800
        }
    }
    
    func bmr(date: Date) async throws -> Int {
        1500
    }
    
    func exercise(date: Date) async throws -> Int {
        600
    }
    
    func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        usleep(10000)
        initialWeight += 1
        return initialWeight
    }
    
    func caloriesConsumedAllDataPoints(applyModifier: Bool) async throws -> [(Date, Int)] {
        []
    }
    
    func caloriesConsumedAllDataPoints(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        []
    }
    
    func bmrBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        []
    }
    
    func activeBetweenDates(fromDate: Date, toDate: Date, applyModifier: Bool) async throws -> [(Date, Int)] {
        []
    }
    
    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Int)] {
        []
    }

    func weeklyWeightChange() async throws -> Int {
        0
    }

    func monthlyWeightChange() async throws -> Int {
        0
    }

    func addFoodEntry(_ foodEntry: FoodEntry) async throws {
        
    }
    
    func deleteFoodEntry(_ foodEntry: FoodEntry) async throws {
        
    }
    
    func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws {
        
    }
    
    func addWeightEntry(_ weightEntry: WeightEntry) async throws {
        
    }
}
