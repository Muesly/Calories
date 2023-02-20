//
//  MealItemsViewModel.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import CoreData

enum MealType: String, Equatable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"
    case eveningSnack = "Evening Snack"

    static func mealTypeForDate(_ date: Date) -> MealType {
        let dc = Calendar.current.dateComponents([.hour], from: date)
        let hour = dc.hour!

        switch(hour) {
        case rangeOfPeriod(.breakfast): return .breakfast
        case rangeOfPeriod(.morningSnack): return .morningSnack
        case rangeOfPeriod(.lunch): return .lunch
        case rangeOfPeriod(.afternoonSnack): return .afternoonSnack
        case rangeOfPeriod(.dinner): return .dinner
        default: return .eveningSnack
        }
    }

    static func rangeOfPeriod(_ type: MealType) -> Range<Int> {
        type.rangeOfPeriod()
    }

    func rangeOfPeriod() -> Range<Int>{
        switch(self) {
        case .breakfast: return 0..<10
        case .morningSnack: return 10..<12
        case .lunch: return 12..<14
        case .afternoonSnack: return 14..<17
        case .dinner: return 17..<20
        default: return 20..<24
        }
    }

    static func rangeOfPeriod(forDate date: Date) -> (Date, Date) {
        let mealType = MealType.mealTypeForDate(date)
        let range = mealType.rangeOfPeriod()
        var dc = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dc.hour = range.startIndex
        let startOfPeriod: Date = Calendar.current.date(from: dc)!
        dc.hour = range.endIndex
        let endOfPeriod: Date = Calendar.current.date(from: dc)!
        return (startOfPeriod, endOfPeriod)
    }
}

struct MealItemsViewModel {
    private let foodEntries: [FoodEntry]

    init(foodEntries: [FoodEntry]) {
        self.foodEntries = foodEntries
    }

    func getMealCalories(currentDate: Date = Date()) -> Int {
        Int(getMealFoodEntries(currentDate: currentDate).reduce(0, { $0 + $1.calories }))
    }

    func getMealTitle(currentDate: Date = Date()) -> String {
        let mealTitle: String = MealType.mealTypeForDate(currentDate).rawValue
        let mealCalories = getMealCalories(currentDate: currentDate)
        return "\(mealTitle) - \(mealCalories) Calories"
    }

    func getMealFoodEntries(currentDate: Date = Date()) -> [FoodEntry] {
        let (startOfPeriod, endOfPeriod) = MealType.rangeOfPeriod(forDate: currentDate)

        return foodEntries.filter { foodEntry in
            guard let timeConsumed = foodEntry.timeConsumed else { return false }
            return (timeConsumed > startOfPeriod) && (timeConsumed < endOfPeriod)
        }.sorted { entry1, entry2 in
            entry1.timeConsumed! > entry2.timeConsumed!
        }
    }
}
