//
//  WeeklyChartViewModel.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
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

class WeeklyChartViewModel {
    let healthStore: HealthStore

    init(healthStore: HealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    private func weekdayStrFromDate(_ date: Date) -> String {
        let weekday = Calendar.current.dateComponents([.weekday], from: date).weekday! - 1
        return Calendar.current.shortWeekdaySymbols[weekday]
    }

    func getDaysCalorieData() async -> ([CalorieDataPointsType], Double) {

        var date: Date = Date()
        var burntData = [CalorieDataPoint]()
        var caloriesConsumedData = [CalorieDataPoint]()

        do {
            for _ in 0..<7 {
                let bmr = try await healthStore.bmr(date: date)
                let exercise = try await healthStore.exercise(date: date)
                burntData.append(.init(weekdayStr: weekdayStrFromDate(date),
                                       calories: bmr + exercise,
                                       barColour: Color.blue))
                date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
            }

            date = Date()
            for _ in 0..<7 {
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
        for i in 0..<7 {
            let calorieDifference = caloriesConsumedData[i].calories - burntData[i].calories
            let barColour = colourForDifference(calorieDifference)
            differenceData.append(.init(weekdayStr: weekdayStrFromDate(date),
                                        calories: calorieDifference,
                                        barColour: barColour))
            date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
        }

        let daysCalorieData: [CalorieDataPointsType] = [.init(barType: "Burnt", dataPoints: burntData.reversed()),
                                                        .init(barType: "Consumed", dataPoints: caloriesConsumedData.reversed()),
                                                        .init(barType: "Difference", dataPoints: differenceData.reversed())]
        let weeklyProgress = max(min(-Double(differenceData.reduce(0, { $0 + $1.calories })) / 3500, 1), 0.001)

        return (daysCalorieData, weeklyProgress)
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

    func calloutViewDetails(for calloutDay: String?, currentDate: Date = Date()) async throws -> CallOutViewDetails {
        guard let calloutDay = calloutDay,
              let calloutDayPos = Calendar.current.shortWeekdaySymbols.firstIndex(of: calloutDay),
              let currentDayPos = Calendar.current.dateComponents([.weekday], from: currentDate).weekday else {
            return CallOutViewDetails()
        }

        var offset = currentDayPos - calloutDayPos - 1
        if offset < 0 {
            offset += 7
        }
        let date: Date = currentDate.addingTimeInterval(TimeInterval(-offset * 86400))
        let endOfDay = Calendar.current.startOfDay(for: date).addingTimeInterval(86399)
        let bmr = try await healthStore.bmr(date: endOfDay)
        let exercise = try await healthStore.exercise(date: endOfDay)
        let caloriesConsumed = try await healthStore.caloriesConsumed(date: endOfDay)

        return CallOutViewDetails(bmr: bmr,
                                  exercise: exercise,
                                  caloriesConsumed: caloriesConsumed)
    }
}

struct CallOutViewDetails: Equatable {
    let bmr: Int
    let exercise: Int
    let caloriesConsumed: Int
    let deficitGoal = 500

    init(bmr: Int = 0,
         exercise: Int = 0,
         caloriesConsumed: Int = 0) {
        self.bmr = bmr
        self.exercise = exercise
        self.caloriesConsumed = caloriesConsumed
    }

    var burnt: Int { bmr + exercise }
    var difference: Int { burnt - caloriesConsumed }
    var canEat: Int { difference - deficitGoal }
}
