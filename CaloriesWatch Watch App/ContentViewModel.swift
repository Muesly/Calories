//
//  ContentViewModel.swift
//  CaloriesWatch Watch App
//
//  Created by Tony Short on 15/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

struct CalorieDataPoint: Identifiable {
    let id = UUID()
    let weekdayStr: String
    let calories: Int
    let barColour: Color
}

struct CalorieDataPointsType: Identifiable {
    let id = UUID()
    let barType: String
    let dataPoints: [CalorieDataPoint]
}

class ContentViewModel: ObservableObject {
    let healthStore: HealthStore
    @Published var daysCaloriesData: [CalorieDataPointsType] = []
    @Published var weeklyProgress: Double = 0.0
    let deficitGoal: Int = -500

    init(healthStore: HealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    private func weekdayStrFromDate(_ date: Date) -> String {
        let weekday = Calendar.current.dateComponents([.weekday], from: date).weekday! - 1
        return Calendar.current.shortWeekdaySymbols[weekday]
    }

    var firstDayStr: String {
        daysCaloriesData.first?.dataPoints.first?.weekdayStr ?? ""
    }

    var lastDayStr: String {
        daysCaloriesData.first?.dataPoints.last?.weekdayStr ?? ""
    }

    @MainActor
    func fetchDaysCalorieData() async {
        var date: Date = Date()
        var burntData = [CalorieDataPoint]()
        var caloriesConsumedData = [CalorieDataPoint]()

        do {
            for _ in 0..<2 {
                let bmr = try await healthStore.bmr(date: date)
                let exercise = try await healthStore.exercise(date: date)
                burntData.append(.init(weekdayStr: weekdayStrFromDate(date),
                                       calories: bmr + exercise,
                                       barColour: Color.blue))
                date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
            }

            date = Date()
            for _ in 0..<2 {
                let caloriesConsumed = try await healthStore.caloriesConsumed(date: date)
                caloriesConsumedData.append(.init(weekdayStr: weekdayStrFromDate(date),
                                                  calories: caloriesConsumed,
                                                  barColour: Color.cyan))
                date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
            }
        } catch {
            print("Failed to fetch burnt or consumed data")
        }

        date = Date()
        var differenceData = [CalorieDataPoint]()
        for i in 0..<2 {
            let calorieDifference = caloriesConsumedData[i].calories - burntData[i].calories
            let barColour = colourForDifference(calorieDifference)
            differenceData.append(.init(weekdayStr: weekdayStrFromDate(date),
                                        calories: calorieDifference,
                                        barColour: barColour))
            date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
        }

        daysCaloriesData = [.init(barType: "Burnt", dataPoints: burntData.reversed()),
                            .init(barType: "Consumed", dataPoints: caloriesConsumedData.reversed()),
                            .init(barType: "Difference", dataPoints: differenceData.reversed())]
        weeklyProgress = max(min(-Double(differenceData.reduce(0, { $0 + $1.calories })) / 3500, 1), 0.001)
    }

    private func colourForDifference(_ difference: Int) -> Color {
        var barColour: Color
        if difference > 0 {
            barColour = .red
        } else if difference > -500 {
            barColour = .orange
        } else {
            barColour = .green
        }
        return barColour
    }
}
