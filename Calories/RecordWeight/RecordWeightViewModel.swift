//
//  RecordWeightViewModel.swift
//  Calories
//
//  Created by Tony Short on 20/02/2023.
//

import Foundation
import HealthKit
import SwiftUI

struct WeightDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let weight: Double
    let deficit: Int

    var stones: Double {
        weight / 14
    }

    static func poundsToStoneAndPoundsStr(stones: Double) -> String {
        let fullStones = Int(stones)
        return "\(fullStones) st \(Int(stones * 14) % fullStones) lbs"
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.date == rhs.date) && (lhs.weight == rhs.weight) && (lhs.deficit == rhs.deficit)
    }

    func weekStr(from fromDate: Date, to toDate: Date) -> String {
        let components = Calendar.current.dateComponents([.weekOfYear], from: fromDate, to: toDate)
        let toDateComps = Calendar.current.dateComponents([.day, .month], from: toDate)
        return "Wk \(components.weekOfYear ?? 0) (\(toDateComps.day ?? 0)/\(toDateComps.month ?? 0))"
    }
}

class RecordWeightViewModel: ObservableObject {
    let healthStore: HealthStore
    @Published var weightData: [WeightDataPoint] = []
    @Published var latestWeight: Int = 0

    init(healthStore: HealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    @MainActor
    func fetchWeightData(date: Date = Date()) async throws {
        try await healthStore.authorize()
        var date = date
        var weightData = [WeightDataPoint]()
        for _ in 0..<8 {  // For last 8 weeks
            // Find most recent data point in last 7 days from now
            if let weightDataPoint = try await healthStore.weight(fromDate: date.startOfWeek,
                                                                  toDate: date) {
                let deficit = await fetchWeeklyDeficits(forDate: date)
                weightData.append(WeightDataPoint(date: date, weight: weightDataPoint, deficit: deficit))
            }
            // Move to start of day, then go to prevous week
            date = date.startOfWeek.addingTimeInterval(-1)
        }
        self.weightData = weightData.reversed()
        self.latestWeight = Int(weightData.last?.weight ?? 0.0)
    }

    func weekStr(forDataPoint dataPoint: WeightDataPoint) -> String {
        let cal = Calendar(identifier: .gregorian)
        guard let firstDate = weightData.first?.date,
              let firstDateStartOfWeek = cal.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: firstDate).date else {
            return ""
        }

        return dataPoint.weekStr(from: firstDateStartOfWeek, to: dataPoint.date)
    }

    var startingWeight: Int {
        Int(weightData.first?.weight ?? 0)
    }

    var currentWeight: String {
        let lastWeight = latestWeight
        let stone = Int(lastWeight/14)
        let pounds = Int(lastWeight) % 14
        return "\(stone) st, \(pounds) lbs"
    }

    var totalLoss: String {
        let startingWeight = startingWeight
        let lastWeight = latestWeight
        let upDownPounds = Int(abs(lastWeight - startingWeight))
        let down = "\u{2193}"
        let up = "\u{2191}"
        return "Progress: \(upDownPounds) lbs \(lastWeight > startingWeight ? up : down)"
    }

    func decreaseWeight() {
        latestWeight -= 1
    }

    func increaseWeight() {
        latestWeight += 1
    }

    func applyNewWeight() async throws {
        try await healthStore.addWeightEntry(WeightEntry(weight: latestWeight, timeRecorded: Date()))
    }

    func fetchWeeklyDeficits(forDate: Date) async -> Int {
        var burntCalories = 0
        var consumedCalories = 0
        do {
            var date = forDate
            for _ in 0..<7 {
                let consumedCaloriesForDay = try await healthStore.caloriesConsumed(date: date)
                if consumedCaloriesForDay == 0 {
                    return 0  // No valid data recorded by user assuming not ultra-fasting
                }
                consumedCalories += consumedCaloriesForDay

                let bmr = try await healthStore.bmr(date: date)
                let exercise = try await healthStore.exercise(date: date)
                burntCalories += bmr + exercise

                date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
            }

        } catch {
            print("Failed to fetch burnt or consumed data")
        }
        print("Difference: \(consumedCalories - burntCalories)")
        return consumedCalories - burntCalories
    }
}

extension Date {
    var startOfWeek: Date {
        Calendar(identifier: .gregorian).dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date!
    }
}
