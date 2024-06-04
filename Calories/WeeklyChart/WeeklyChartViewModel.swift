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
    let calories: Int
    let stat: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.calories == rhs.calories) && (lhs.stat == rhs.stat)
    }
}

class WeeklyChartViewModel: ObservableObject {
    let healthStore: HealthStore
    let deficitGoal: Int = -500
    let numberOfDays: Int
    let startOfWeekFormatter = DateFormatter()

    var startDate: Date?

    @Published var daysCaloriesData: [CalorieDataPointsType] = []
    @Published var weeklyData: [WeeklyStat] = []
    @Published var startOfWeek: String = ""
    @Published var previousWeekEnabled: Bool = false
    @Published var nextWeekEnabled: Bool = false

    init(healthStore: HealthStore = HKHealthStore(),
         numberOfDays: Int = 7) {
        self.healthStore = healthStore
        self.numberOfDays = numberOfDays
        self.startDate = startOfWeek()
    }

    private func startOfWeek(_ date: Date = Date()) -> Date {
        var weekday = Calendar.current.dateComponents([.weekday], from: date).weekday!
        if weekday == 1 {
            weekday += 7    // for Sun
        }
        return date.startOfDay.addingTimeInterval(-Double(weekday - 2) * secsPerDay)
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

    private func caloriesConsumedPresentForDate(_ date: Date) async -> Bool {
        do {
            let caloriesConsumed = try await healthStore.caloriesConsumed(date: date)
            return caloriesConsumed > 0
        } catch {
            return false
        }
    }

    @MainActor
    func fetchDaysCalorieData(currentDate: Date = Date()) async {
        guard let startDate = startDate else {
            return
        }
        var nextDate = startDate
        var burntData = [CalorieDataPoint]()
        var caloriesConsumedData = [CalorieDataPoint]()

        do {
            for _ in 0..<7 {
                var bmr = 0
                var exercise = 0
                if nextDate <= currentDate {
                    bmr = try await healthStore.bmr(date: nextDate)
                    exercise = try await healthStore.exercise(date: nextDate)
                }
                burntData.append(.init(date: nextDate,
                                       weekdayStr: weekdayStrFromDate(nextDate),
                                       calories: bmr + exercise,
                                       barColour: Color.blue))
                nextDate.addTimeInterval(secsPerDay)
            }

            nextDate = startDate
            for _ in 0..<7 {
                var caloriesConsumed = 0
                if nextDate <= currentDate {
                    caloriesConsumed = try await healthStore.caloriesConsumed(date: nextDate)
                }
                caloriesConsumedData.append(.init(date: nextDate,
                                                  weekdayStr: weekdayStrFromDate(nextDate),
                                                  calories: caloriesConsumed,
                                                  barColour: Color.cyan))
                nextDate.addTimeInterval(secsPerDay)
            }
        } catch {
            print("Failed to fetch burnt or consumed data")
        }

        nextDate = startDate
        var differenceData = [CalorieDataPoint]()
        for i in 0..<7 {
            var calorieDifference = 0
            if nextDate <= currentDate {
                calorieDifference = caloriesConsumedData[i].calories - burntData[i].calories
            }
            let barColour = Self.colourForDifference(calorieDifference)
            differenceData.append(.init(date: nextDate,
                                        weekdayStr: weekdayStrFromDate(nextDate),
                                        calories: calorieDifference,
                                        barColour: barColour))
            nextDate.addTimeInterval(secsPerDay)
        }

        // Calculate weekly progres before cropping to e.g. two days for watch app
        let progress = -differenceData.reduce(0, { $0 + $1.calories })
        if progress < 3500 {
            weeklyData = [WeeklyStat(calories: progress, stat: "Burnt")]
            weeklyData.append(WeeklyStat(calories: 3500 - progress, stat: "To Go"))
            weeklyData.append(WeeklyStat(calories: 0, stat: "Can Eat"))
        } else if progress > 3500 {
            weeklyData = [WeeklyStat(calories: 3500, stat: "Burnt")]
            weeklyData.append(WeeklyStat(calories: 0, stat: "To Go"))
            weeklyData.append(WeeklyStat(calories: progress - 3500, stat: "Can Eat"))
        }

        startOfWeek = findStartOfWeek(data: differenceData)

        let croppedBurntData = Array(burntData[..<numberOfDays])
        let croppedCaloriesConsumedData = Array(caloriesConsumedData[..<numberOfDays])
        let croppedDifferenceData = Array(differenceData[..<numberOfDays])

        daysCaloriesData = [.init(barType: "Burnt", dataPoints: croppedBurntData),
                            .init(barType: "Consumed", dataPoints: croppedCaloriesConsumedData),
                            .init(barType: "Difference", dataPoints: croppedDifferenceData)]
        previousWeekEnabled = await caloriesConsumedPresentForDate(startDate.addingTimeInterval(-secsPerWeek))
        nextWeekEnabled = startDate.addingTimeInterval(secsPerWeek) < Date()
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

    func calloutViewDetails(for calloutDay: String?) async throws -> CallOutViewDetails {
        guard let calloutDay = calloutDay,
              let calloutDayPos = Calendar.current.shortWeekdaySymbols.firstIndex(of: calloutDay),
              let startDate = startDate else {
            return CallOutViewDetails()
        }
        var offset = calloutDayPos - 1
        if offset == -1 {
            offset += 7
        }
        let date: Date = startOfWeek(startDate).addingTimeInterval(secsPerDay * Double(offset))
        let endOfDay = Calendar.current.startOfDay(for: date).addingTimeInterval(secsPerDay - 1)
        let bmr = try await healthStore.bmr(date: endOfDay)
        let exercise = try await healthStore.exercise(date: endOfDay)
        let caloriesConsumed = try await healthStore.caloriesConsumed(date: endOfDay)

        return CallOutViewDetails(date: date,
                                  bmr: bmr,
                                  exercise: exercise,
                                  caloriesConsumed: caloriesConsumed)
    }

    func previousWeekPressed() {
        Task {
            startDate?.addTimeInterval(-secsPerWeek)
            await fetchDaysCalorieData()
        }
    }

    func nextWeekPressed() {
        Task {
            startDate?.addTimeInterval(secsPerWeek)
            await fetchDaysCalorieData()
        }
    }
}

struct CallOutViewDetails: Equatable {
    private let date: Date
    private static var df: DateFormatter = .init()
    let bmr: Int
    let exercise: Int
    let caloriesConsumed: Int
    let deficitGoal = 500

    init(date: Date = Date(),
         bmr: Int = 0,
         exercise: Int = 0,
         caloriesConsumed: Int = 0) {
        self.date = date
        self.bmr = bmr
        self.exercise = exercise
        self.caloriesConsumed = caloriesConsumed
    }

    var dateFormatter: DateFormatter {
        Self.df.dateFormat = "EEEE, MMM d"
        return Self.df
    }

    var dateStr: String {
        dateFormatter.string(from: date)
    }
    
    var burnt: Int { bmr + exercise }
    var difference: Int { burnt - caloriesConsumed }
    var canEat: Int { difference - deficitGoal }
}
