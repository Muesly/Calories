//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import Foundation
import SwiftUI
import UserNotifications

@main
struct CaloriesApp: App {
    let isUITesting: Bool
    var healthStore: HealthStore {
        isUITesting ? HealthStoreFactory.createNull() : HealthStoreFactory.create()
    }

    var companion: Companion {
        isUITesting ? Companion.createNull() : Companion.create()
    }

    init() {
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        requestNotificationsPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            CaloriesView(historyViewModel: HistoryViewModel(healthStore: healthStore),
                         weeklyChartViewModel: WeeklyChartViewModel(healthStore: healthStore),
                         healthStore: healthStore,
                         companion: companion)
            //DataView()
        }
    }

    private func requestNotificationsPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
            if granted {
            } else if let error = error {
                print("Permission denied: \(error.localizedDescription)")
            }
        }
    }
}

class StubbedHealthStore: HealthStore {
    func authorize() async throws {}
    
    func caloriesConsumed(date: Date) async throws -> Int {
        2000
    }
    
    func bmr(date: Date) async throws -> Int {
        1500
    }
    
    func exercise(date: Date) async throws -> Int {
        600
    }
    
    func weight(fromDate: Date, toDate: Date) async throws -> Int? {
        sleep(1)
        return 200
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
