//
//  MealPlanningViewModel.swift
//  Calories
//
//  Created by Tony Short on 08/07/2025.
//

import Foundation

enum Person: String, CaseIterable {
    case tony = "Tony"
    case karen = "Karen"
}

struct MealSelection {
    var person: Person
    var date: Date
    var mealType: MealType
    var isSelected: Bool

    var id: String {
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        return "\(person.rawValue)-\(dateString)-\(mealType.rawValue)"
    }
}

enum WizardStage: Int, CaseIterable {
    case mealAvailability
    case foodToUseUp
    case mealPicking
}

struct FoodToUseUp: Identifiable {
    let id: UUID
    var name: String
    var isFullMeal: Bool  // true = complete meal (🍲), false = ingredient (🥩)
    var isFrozen: Bool  // needs thawing consideration

    init(name: String = "", isFullMeal: Bool = false, isFrozen: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isFullMeal = isFullMeal
        self.isFrozen = isFrozen
    }

    var typeEmoji: String {
        isFullMeal ? "🍲" : "🥩"
    }
}

// MARK: - View Model

@MainActor
class MealPlanningViewModel: ObservableObject {
    @Published var currentStage: WizardStage = .mealPicking
    @Published var mealSelections: [MealSelection] = []
    @Published var mealReasons: [String: String] = [:]
    @Published var quickMeals: [String: Bool] = [:]
    @Published var foodToUseUp: [FoodToUseUp] = []
    let weekDates: [Date]

    init() {
        // Generate next 7 days starting from tomorrow
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        self.weekDates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: tomorrow)
        }

        for person in Person.allCases {
            for date in weekDates {
                for mealType in MealType.allCases {
                    mealSelections.append(
                        .init(person: person, date: date, mealType: mealType, isSelected: true))
                }
            }
        }
    }

    var canGoBack: Bool {
        currentStage != WizardStage.allCases.first
    }

    func goToPreviousStage() {
        let allStages = WizardStage.allCases
        if let currentIndex = allStages.firstIndex(of: currentStage), currentIndex > 0 {
            currentStage = allStages[currentIndex - 1]
        }
    }

    var canGoForward: Bool {
        currentStage != WizardStage.allCases.last
    }

    func goToNextStage() {
        let allStages = WizardStage.allCases
        if let currentIndex = allStages.firstIndex(of: currentStage),
            currentIndex < allStages.count - 1
        {
            currentStage = allStages[currentIndex + 1]
        }
    }

    // MARK: - Private Helpers

    /// Checks if a meal selection matches the given criteria
    private func matchesMeal(
        selection: MealSelection, person: Person, date: Date, mealType: MealType
    ) -> Bool {
        selection.person == person && date.isSameDay(as: selection.date)
            && selection.mealType == mealType
    }

    /// Generates a storage key for person-specific meal data
    private static func personMealKey(person: Person, date: Date, mealType: MealType) -> String {
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        return "\(person.rawValue)-\(dateString)-\(mealType.rawValue)"
    }

    /// Generates a storage key for meal-level data (not person-specific)
    private static func mealKey(date: Date, mealType: MealType) -> String {
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        return "\(dateString)-\(mealType.rawValue)"
    }

    // MARK: - Meal Selection

    func toggleMealSelection(for person: Person, date: Date, mealType: MealType) {
        if let index = mealSelections.firstIndex(where: { selection in
            matchesMeal(selection: selection, person: person, date: date, mealType: mealType)
        }) {
            mealSelections[index].isSelected.toggle()
        }
    }

    func isSelected(for person: Person, date: Date, mealType: MealType) -> Bool {
        return mealSelections.first { selection in
            matchesMeal(selection: selection, person: person, date: date, mealType: mealType)
        }?.isSelected ?? false
    }

    // MARK: - Meal Reasons

    func setReason(_ reason: String, for person: Person, date: Date, mealType: MealType) {
        let key = Self.personMealKey(person: person, date: date, mealType: mealType)
        if reason.isEmpty {
            mealReasons.removeValue(forKey: key)
        } else {
            mealReasons[key] = reason
        }
    }

    func getReason(for person: Person, date: Date, mealType: MealType) -> String {
        mealReasons[Self.personMealKey(person: person, date: date, mealType: mealType)] ?? ""
    }

    // MARK: - Quick Meals

    func setQuickMeal(_ isQuick: Bool, for date: Date, mealType: MealType) {
        let key = Self.mealKey(date: date, mealType: mealType)
        quickMeals[key] = isQuick
    }

    func isQuickMeal(for date: Date, mealType: MealType) -> Bool {
        quickMeals[Self.mealKey(date: date, mealType: mealType)] ?? false
    }

    // MARK: - Food To Use Up

    func addFoodItem() {
        foodToUseUp.append(FoodToUseUp())
    }

    func removeFoodItem(at index: Int) {
        guard index >= 0 && index < foodToUseUp.count else { return }
        foodToUseUp.remove(at: index)
    }

    func removeFoodItem(withId id: UUID) {
        foodToUseUp.removeAll { $0.id == id }
    }

    func updateFoodItem(_ item: FoodToUseUp) {
        if let index = foodToUseUp.firstIndex(where: { $0.id == item.id }) {
            foodToUseUp[index] = item
        }
    }
}
