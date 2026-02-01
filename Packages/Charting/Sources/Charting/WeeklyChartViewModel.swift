//
//  WeeklyChartViewModel.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Foundation
import HealthKit
import SwiftData
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
    let weightLossInLbs: Double
    let stat: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.weightLossInLbs == rhs.weightLossInLbs) && (lhs.stat == rhs.stat)
    }
}

protocol IDGeneratorType {
    func generate() -> String
}

struct IDGenerator: IDGeneratorType {
    func generate() -> String {
        UUID().uuidString
    }
}

struct WeeklyPlantsStat: Identifiable, Equatable {
    let id: String
    let numPlants: Int
    let stat: String

    init(id: String, numPlants: Int, stat: String) {
        self.id = id
        self.numPlants = numPlants
        self.stat = stat
    }
}

@Observable
@MainActor
class WeeklyChartViewModel {
    let healthStore: HealthStore
    var modelContext: ModelContext?
    let idGenerator: IDGeneratorType

    let deficitGoal: Int = -500
    var plantGoal: Int = 30
    let numberOfDays: Int
    let startOfWeekFormatter = DateFormatter()

    var startDate: Date?

    var daysCaloriesData: [CalorieDataPointsType] = []
    var weeklyData: [WeeklyStat] = []
    var weeklyPlantsData: [WeeklyPlantsStat] = []
    var startOfWeek: String = ""
    var previousWeekEnabled: Bool = false
    var nextWeekEnabled: Bool = false
    let currentDate: Date

    init(
        healthStore: HealthStore,
        numberOfDays: Int = 7,
        idGenerator: IDGeneratorType = IDGenerator(),
        currentDate: Date
    ) {
        self.healthStore = healthStore
        self.numberOfDays = numberOfDays
        self.idGenerator = idGenerator
        self.currentDate = currentDate
        self.startDate = startOfWeek()
    }

    func dayStr(forDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let day = Int(dateFormatter.string(from: date))?.ordinal ?? ""

        dateFormatter.dateFormat = "MMM"
        let month = dateFormatter.string(from: date)

        return "\(day) \(month)"
    }

    var weekStr: String {
        let date = startOfWeek(startDate ?? Date())
        return "\(dayStr(forDate: date)) to \(dayStr(forDate: date.addingTimeInterval(7 * 86400)))"
    }

    private func startOfWeek(_ date: Date = Date()) -> Date {
        var weekday = Calendar.current.dateComponents([.weekday], from: date).weekday!
        if weekday == 1 {
            weekday += 7  // for Sun
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

    func fetchData(currentDate: Date) async {
        await fetchWeeklyData(currentDate: currentDate)
        fetchWeeklyPlantsData()
    }

    func fetchWeeklyData(currentDate: Date) async {
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
                burntData.append(
                    .init(
                        date: nextDate,
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
                caloriesConsumedData.append(
                    .init(
                        date: nextDate,
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
            differenceData.append(
                .init(
                    date: nextDate,
                    weekdayStr: weekdayStrFromDate(nextDate),
                    calories: calorieDifference,
                    barColour: barColour))
            nextDate.addTimeInterval(secsPerDay)
        }

        // Calculate weekly progress
        let burnt = -differenceData.reduce(0.0, { $0 + Double($1.calories) })
        if burnt > 0 {
            let goodBurn = Double(min(3500, burnt))
            let canEat = Double(max(0, burnt - 3500))
            let toGo = Double(max(0, 3500 - goodBurn))
            weeklyData = [
                WeeklyStat(weightLossInLbs: goodBurn / 3500, stat: "Good"),
                WeeklyStat(weightLossInLbs: toGo / 3500, stat: "To Go"),
                WeeklyStat(weightLossInLbs: canEat / 3500, stat: "Can Eat"),
            ]
        } else {
            let badBurn = burnt / 3500
            let toGo = 1.0
            weeklyData = [
                WeeklyStat(weightLossInLbs: badBurn, stat: "Bad"),
                WeeklyStat(weightLossInLbs: toGo, stat: "To Go"),
            ]
        }

        startOfWeek = findStartOfWeek(data: differenceData)

        let croppedBurntData = Array(burntData[..<numberOfDays])
        let croppedCaloriesConsumedData = Array(caloriesConsumedData[..<numberOfDays])
        let croppedDifferenceData = Array(differenceData[..<numberOfDays])

        daysCaloriesData = [
            .init(barType: "Burnt", dataPoints: croppedBurntData),
            .init(barType: "Consumed", dataPoints: croppedCaloriesConsumedData),
            .init(barType: "Difference", dataPoints: croppedDifferenceData),
        ]
        previousWeekEnabled = await caloriesConsumedPresentForDate(
            startDate.addingTimeInterval(-secsPerWeek))
        nextWeekEnabled = startDate.addingTimeInterval(secsPerWeek) < Date()
    }

    var weeklyDataMinX: Double {
        weeklyData.map { $0.weightLossInLbs }.min() ?? 0
    }

    var weeklyDataMaxX: Double {
        var maxX = 1.0
        if weeklyData.count == 3 {
            let burnt = weeklyData[0].weightLossInLbs + weeklyData[2].weightLossInLbs
            if burnt > 0 {
                maxX = max(burnt, maxX)
            }
        }
        return maxX
    }

    func fetchWeeklyPlantsData() {
        guard let modelContext, let startDate else { return }
        let endDate = startDate.addingTimeInterval(7 * 86400)
        let foodEntries = modelContext.foodResults(
            for: #Predicate {
                ($0.timeConsumed >= startDate) && ($0.timeConsumed < endDate)
            })
        let numPlants = Set(foodEntries.flatMap { $0.plants ?? [] }).count
        let abundance = max(0, numPlants - plantGoal)
        let eaten = numPlants - abundance
        let toGo = max(0, plantGoal - numPlants)
        weeklyPlantsData = [
            WeeklyPlantsStat(id: idGenerator.generate(), numPlants: eaten, stat: "Eaten"),
            WeeklyPlantsStat(id: idGenerator.generate(), numPlants: toGo, stat: "To Go"),
            WeeklyPlantsStat(id: idGenerator.generate(), numPlants: abundance, stat: "Abundance"),
        ]
    }

    var weeklyPlantsDataMaxX: Int {
        weeklyPlantsData.reduce(0, { $0 + $1.numPlants })
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

    func previousWeekPressed() {
        Task {
            startDate?.addTimeInterval(-secsPerWeek)
            await fetchData(currentDate: currentDate)
        }
    }

    func nextWeekPressed() {
        Task {
            startDate?.addTimeInterval(secsPerWeek)
            await fetchData(currentDate: currentDate)
        }
    }
}

extension Int {
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
