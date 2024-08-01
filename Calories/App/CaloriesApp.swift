//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

@main
struct CaloriesApp: App {
    let isUITesting: Bool
    var healthStore: HealthStore {
        isUITesting ? StubbedHealthStore() : HKHealthStore()
    }
    
    init() {
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }
    
    var body: some Scene {
        WindowGroup {
            CaloriesView(historyViewModel: HistoryViewModel(healthStore: healthStore), weeklyChartViewModel: WeeklyChartViewModel(healthStore: healthStore))
                .environment(\.healthStore, healthStore)
            //DataView()
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
    
    func weight(fromDate: Date, toDate: Date) async throws -> Double? {
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
    
    func weightBetweenDates(fromDate: Date, toDate: Date) async throws -> [(Date, Double)] {
        []
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
