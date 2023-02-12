//
//  CalorieStats.swift
//  Calories
//
//  Created by Tony Short on 12/02/2023.
//

import HealthKit

class CalorieStats: ObservableObject {
    let healthStore: HealthStore

    init(healthStore: HealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    var bmr: Int = 0
    var exercise: Int = 0
    var caloriesConsumed: Int = 0
    let deficitGoal = 500
    var combinedExpenditure: Int { bmr + exercise }
    var difference: Int { bmr + exercise - caloriesConsumed }
    var canEat: Int { bmr + exercise - caloriesConsumed - deficitGoal }

    func fetchCaloriesConsumed() {
        Task {
            do {
                caloriesConsumed = try await healthStore.caloriesConsumed()
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            } catch {
                print("Failed to fetch stats")
            }
        }
    }

    func fetchStats() {
        Task {
            do {
                bmr = try await healthStore.bmr()
                exercise = try await healthStore.exercise()
                caloriesConsumed = try await healthStore.caloriesConsumed()
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            } catch {
                print("Failed to fetch stats")
            }
        }
    }
}
