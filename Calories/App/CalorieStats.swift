//
//  CalorieStats.swift
//  Calories
//
//  Created by Tony Short on 12/02/2023.
//

import HealthKit

protocol Dispatching {
    func async(execute work: @escaping @convention(block) () -> Void)
}

extension DispatchQueue: Dispatching {
    func async(execute work: @escaping @convention(block) () -> Void) {
        async(group: nil, qos: .unspecified, flags: [], execute: work)
    }
}
class CalorieStats: ObservableObject {
    let healthStore: HealthStore
    let dispatchQueue: Dispatching

    init(healthStore: HealthStore = HKHealthStore(),
         dispatchQueue: Dispatching = DispatchQueue.main) {
        self.healthStore = healthStore
        self.dispatchQueue = dispatchQueue
    }

    var bmr: Int = 0
    var exercise: Int = 0
    var caloriesConsumed: Int = 0
    var deficitGoal: Int {
        let dc = Calendar.current.dateComponents([.hour, .minute, .day], from: Date())
        let ratio: Double = Double((dc.hour! * 60) + dc.minute!) / 1440.0
        return Int(ratio * 500)
    }
    var combinedExpenditure: Int { bmr + exercise }
    var difference: Int { bmr + exercise - caloriesConsumed }
    var canEat: Int { bmr + exercise - caloriesConsumed - deficitGoal }

    func fetchCaloriesConsumed() async {
        do {
            caloriesConsumed = try await healthStore.caloriesConsumed()
            dispatchQueue.async {
                self.objectWillChange.send()
            }
        } catch {
            print("Failed to fetch stats")
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
