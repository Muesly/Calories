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
    let date: Date
    let weekdayStr: String
    let calories: Int
    let barColour: Color
}

struct CalorieDataPointsType: Identifiable {
    let id = UUID()
    let barType: String
    let dataPoints: [CalorieDataPoint]
}

struct WeeklyStat: Identifiable, Equatable {
    let id = UUID()
    let department: String
    let calories: Int
    let stat: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.department == rhs.department) && (lhs.calories == rhs.calories) && (lhs.stat == rhs.stat)
    }
}

class WeeklyChartViewModel: ObservableObject {
    let healthStore: HealthStore
    let deficitGoal: Int = -500
    let numberOfDays: Int
    let startOfWeekFormatter = DateFormatter()

    @MainActor
    var startDate: Date = Date()

    @Published var daysCaloriesData: [CalorieDataPointsType] = []
    @Published var weeklyData: [WeeklyStat] = []
    @Published var startOfWeek: String = ""

    init(healthStore: HealthStore = HKHealthStore(),
         numberOfDays: Int = 7) {
        self.healthStore = healthStore
        self.numberOfDays = numberOfDays
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
    func fetchDaysCalorieData(forDate date: Date? = nil) async {
        var date = date ?? startDate
        startDate = date
        print("start date: \(startDate)")
        var burntData = [CalorieDataPoint]()
        var caloriesConsumedData = [CalorieDataPoint]()

        do {
            for _ in 0..<7 {
                let bmr = try await healthStore.bmr(date: date)
                let exercise = try await healthStore.exercise(date: date)
                burntData.append(.init(date: date,
                                       weekdayStr: weekdayStrFromDate(date),
                                       calories: bmr + exercise,
                                       barColour: Color.blue))
                date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
            }

            date = Date()
            for _ in 0..<7 {
                let caloriesConsumed = try await healthStore.caloriesConsumed(date: date)
                caloriesConsumedData.append(.init(date: date,
                                                  weekdayStr: weekdayStrFromDate(date),
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
            let barColour = Self.colourForDifference(calorieDifference)
            differenceData.append(.init(date: date,
                                        weekdayStr: weekdayStrFromDate(date),
                                        calories: calorieDifference,
                                        barColour: barColour))
            date = Calendar.current.startOfDay(for: date).addingTimeInterval(-1)    // Move to end of previous dat
        }

        // Calculate weekly progres before cropping to e.g. two days for watch app
        let progress = progressSinceMonday(data: differenceData.reversed())
        weeklyData = [WeeklyStat(department: "Production", calories: min(progress, 3500), stat: "Burnt")]
        if progress < 3500 {
            weeklyData.append(WeeklyStat(department: "Production", calories: 3500 - progress, stat: "To Go"))
            weeklyData.append(WeeklyStat(department: "Production", calories: 0, stat: "Can Eat"))
        } else if progress > 3500 {
            weeklyData.append(WeeklyStat(department: "Production", calories: 0, stat: "To Go"))
            weeklyData.append(WeeklyStat(department: "Production", calories: progress - 3500, stat: "Can Eat"))
        }

        startOfWeek = findStartOfWeek(data: differenceData.reversed())

        let croppedBurntData = Array(burntData[..<numberOfDays])
        let croppedCaloriesConsumedData = Array(caloriesConsumedData[..<numberOfDays])
        let croppedDifferenceData = Array(differenceData[..<numberOfDays])

        daysCaloriesData = [.init(barType: "Burnt", dataPoints: croppedBurntData.reversed()),
                            .init(barType: "Consumed", dataPoints: croppedCaloriesConsumedData.reversed()),
                            .init(barType: "Difference", dataPoints: croppedDifferenceData.reversed())]
    }

    private func progressSinceMonday(data: [CalorieDataPoint]) -> Int {
        guard let mondayIndex = data.firstIndex(where: { $0.weekdayStr == "Mon" }) else {
            return 0
        }
        let index = mondayIndex
        return -data[index...].reduce(0, { $0 + $1.calories })
    }

    private func findStartOfWeek(data: [CalorieDataPoint]) -> String {
        guard let mondayData = data.first(where: { $0.weekdayStr == "Mon" }) else {
            return ""
        }

        startOfWeekFormatter.dateFormat = "EEEE, MMM d"
        let startOfWeek = startOfWeekFormatter.string(from: mondayData.date)
        return startOfWeek
    }

    static func colourForDifference(_ difference: Int) -> Color {
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

    func previousWeekPressed() {
        Task {
            await fetchDaysCalorieData(forDate: startDate.addingTimeInterval(-7 * 86400))
        }
    }

    func nextWeekPressed() {
        Task {
            await fetchDaysCalorieData(forDate: startDate.addingTimeInterval(7 * 86400))
        }
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
