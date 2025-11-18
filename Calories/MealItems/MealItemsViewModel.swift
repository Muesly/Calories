//
//  MealItemsViewModel.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import SwiftData
import SwiftUI

enum MealType: String, CaseIterable, Equatable, Identifiable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"
    case eveningSnack = "Evening Snack"

    var id: String { rawValue }

    static func mealTypeForDate(_ date: Date) -> MealType {
        let dc = Calendar.current.dateComponents([.hour], from: date)
        let hour = dc.hour!

        switch hour {
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

    func rangeOfPeriod() -> Range<Int> {
        switch self {
        case .breakfast: return 0..<10
        case .morningSnack: return 10..<12
        case .lunch: return 12..<14
        case .afternoonSnack: return 14..<17
        case .dinner: return 17..<20
        default: return 20..<24
        }
    }

    func mealTypeColor() -> Color {
        switch self {
        case .breakfast: return .red
        case .morningSnack: return .orange
        case .lunch: return .yellow
        case .afternoonSnack: return .green
        case .dinner: return .blue
        default: return .purple
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

    var shortened: String {
        String(id.prefix(1))
    }
}

@Observable
@MainActor
class MealItemsViewModel {
    private let modelContext: ModelContext
    var mealFoodEntries: [FoodEntry] = []
    var mealTitle: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchMealFoodEntries(date: Date) {
        let (startOfPeriod, endOfPeriod) = MealType.rangeOfPeriod(forDate: date)
        let entries = modelContext.foodResults(
            for: #Predicate {
                ($0.timeConsumed >= startOfPeriod) && ($0.timeConsumed < endOfPeriod)
            })
        mealFoodEntries = entries.sorted { entry1, entry2 in
            entry1.timeConsumed > entry2.timeConsumed
        }
        let mealCalories = Int(mealFoodEntries.reduce(0, { $0 + $1.calories }))
        let mealType: String = MealType.mealTypeForDate(date).rawValue
        mealTitle = "\(mealType) - \(mealCalories) Calories"
    }
}
