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
    let calories: Int
    let stat: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.calories == rhs.calories) && (lhs.stat == rhs.stat)
    }
}

struct WeeklyPlantsStat: Identifiable, Equatable {
    var id = UUID()
    let numPlants: Int
    let stat: String

    static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.numPlants == rhs.numPlants) && (lhs.stat == rhs.stat)
    }
}

@Observable
class WeeklyChartViewModel {
    let healthStore: HealthStore
    var modelContext: ModelContext?
    let deficitGoal: Int = -500
    let plantGoal: Int = 30
    let numberOfDays: Int
    let startOfWeekFormatter = DateFormatter()
    
    var startDate: Date?
    
    var daysCaloriesData: [CalorieDataPointsType] = []
    var weeklyData: [WeeklyStat] = []
    var weeklyPlantsData: [WeeklyPlantsStat] = []
    var startOfWeek: String = ""
    var previousWeekEnabled: Bool = false
    var nextWeekEnabled: Bool = false
    
    init(healthStore: HealthStore,
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
    func fetchData(currentDate: Date = Date()) async {
        await fetchWeeklyData(currentDate: currentDate)
        fetchWeeklyPlantsData()
    }

    @MainActor
    func fetchWeeklyData(currentDate: Date = Date()) async {
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
            weeklyData = [WeeklyStat(calories: progress, stat: "Burnt"),
                          WeeklyStat(calories: 3500 - progress, stat: "To Go"),
                          WeeklyStat(calories: 0, stat: "Can Eat")]
        } else if progress > 3500 {
            weeklyData = [WeeklyStat(calories: 3500, stat: "Burnt"),
                          WeeklyStat(calories: 0, stat: "To Go"),
                          WeeklyStat(calories: progress - 3500, stat: "Can Eat")]
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

    func fetchWeeklyPlantsData() {
        guard let modelContext, let startDate else { return }
        let endDate = startDate.addingTimeInterval(7 * 86400)
        let foodEntries = modelContext.foodResults(for: #Predicate {
            ($0.timeConsumed >= startDate) && ($0.timeConsumed < endDate)})
        let numPlants = Set(foodEntries.flatMap { $0.plants ?? [] }).count
        weeklyPlantsData = [WeeklyPlantsStat(numPlants: numPlants, stat: "Eaten"),
                            WeeklyPlantsStat(numPlants: max(0, plantGoal - numPlants), stat: "To Go"),
                            WeeklyPlantsStat(numPlants: max(0, numPlants - plantGoal), stat: "Abundance")]
        print(weeklyPlantsData.map { "\($0.numPlants) - \($0.stat)" })
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
            await fetchData()
        }
    }
    
    func nextWeekPressed() {
        Task {
            startDate?.addTimeInterval(secsPerWeek)
            await fetchData()
        }
    }
}
