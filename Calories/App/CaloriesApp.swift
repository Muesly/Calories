//
//  CaloriesApp.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import Foundation
import HealthKit
import SwiftUI
import UserNotifications

@main
struct CaloriesApp: App {
    let isUITesting: Bool
    var healthStore: HealthStore {
        isUITesting ? StubbedHealthStore() : HKHealthStore()
    }
    
    init() {
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        requestNotificationsPermission()
        scheduleTomorrowsMotivationalMessage()
    }
    
    var body: some Scene {
        WindowGroup {
            CaloriesView(historyViewModel: HistoryViewModel(healthStore: healthStore), weeklyChartViewModel: WeeklyChartViewModel(healthStore: healthStore))
                .environment(\.healthStore, healthStore)
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

    private func scheduleTomorrowsMotivationalMessage() {
        let content = UNMutableNotificationContent()

        var dateComponents = tomorrowDateComponents()
        let companion = Companion(messageDetails: [
            CompanionMessageDetails(message: "Rise and Shine! What’s good for breakfast?", timeOfDay: .earlyMorning),
            CompanionMessageDetails(message: "Time for a quick stretch! Your muscles will thank you.", timeOfDay: .midMorning),
            CompanionMessageDetails(message: "The only bad workout is the one you didn't do.", timeOfDay: .anyTime)
        ]
)
        let (message, scheduledHour) = companion.nextMotivationalMessage()
        dateComponents.hour = scheduledHour

        content.body = message
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }

    private func tomorrowDateComponents() -> DateComponents {
        let tomorrow = Date().addingTimeInterval(86400)
        return Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
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
    
    func addFoodEntry(_ foodEntry: FoodEntry) async throws {
        
    }
    
    func deleteFoodEntry(_ foodEntry: FoodEntry) async throws {
        
    }
    
    func addExerciseEntry(_ exerciseEntry: ExerciseEntry) async throws {
        
    }
    
    func addWeightEntry(_ weightEntry: WeightEntry) async throws {
        
    }
}
