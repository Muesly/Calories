//
//  MealItemsViewModel.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import CaloriesFoundation
import Foundation
import SwiftData
import SwiftUI

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
