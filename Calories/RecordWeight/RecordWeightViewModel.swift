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

    var stones: Double {
        weight / 14
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.date == rhs.date) && (lhs.weight == rhs.weight)
    }

    func weekStr(from fromDate: Date, to toDate: Date) -> String {
        let components = Calendar.current.dateComponents([.weekOfYear], from: fromDate, to: toDate)
        return "Week \(components.weekOfYear ?? 0)"
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
            if let weightDataPoint = try await healthStore.weight(date: date) {
                weightData.append(WeightDataPoint(date: date, weight: weightDataPoint))
            }
            // Move to start of day, then go to prevous week
            date = Calendar.current.startOfDay(for: date).addingTimeInterval(-7 * 86400)
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
}
