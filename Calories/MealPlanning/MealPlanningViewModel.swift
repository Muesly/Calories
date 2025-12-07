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
    var day: DayOfWeek
    var mealType: MealType
    var isSelected: Bool

    var id: String {
        "\(person.rawValue)-\(day)-\(mealType.rawValue)"
    }
}

enum WizardStage: Int, CaseIterable {
    case mealAvailability
    case freezerMeals
    case existingItems
    case mealPicking
}

// MARK: - View Model

@MainActor
class MealPlanningViewModel: ObservableObject {
    @Published var currentStage: WizardStage = .mealAvailability
    @Published var mealSelections: [MealSelection] = []
    @Published var mealReasons: [String: String] = [:]
    @Published var quickMeals: [String: Bool] = [:]

    init() {
        for person in [Person.tony, Person.karen] {
            for day in DayOfWeek.allCases {
                for mealType in MealType.allCases {
                    mealSelections.append(
                        .init(person: person, day: day, mealType: mealType, isSelected: true))
                }
            }
        }
    }

    var daysOfWeek: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        let firstWeekdayIndex = Calendar.current.firstWeekday - 1  // Make it zero-based

        guard let symbols = dateFormatter.weekdaySymbols else {
            return []
        }

        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
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

    func toggleMealSelection(for person: Person, day: DayOfWeek, mealType: MealType) {
        if let index = mealSelections.firstIndex(where: { selection in
            selection.person == person && selection.day == day && selection.mealType == mealType
        }) {
            mealSelections[index].isSelected.toggle()
        }
    }

    func isSelected(for person: Person, day: DayOfWeek, mealType: MealType) -> Bool {
        return mealSelections.first { selection in
            selection.person == person && selection.day == day && selection.mealType == mealType
        }?.isSelected ?? false
    }

    private static func reasonKey(person: Person, day: DayOfWeek, mealType: MealType) -> String {
        "\(person.rawValue)-\(day.rawValue)-\(mealType.rawValue)"
    }

    func setReason(_ reason: String, for person: Person, day: DayOfWeek, mealType: MealType) {
        let key = Self.reasonKey(person: person, day: day, mealType: mealType)
        if reason.isEmpty {
            mealReasons.removeValue(forKey: key)
        } else {
            mealReasons[key] = reason
        }
    }

    func getReason(for person: Person, day: DayOfWeek, mealType: MealType) -> String {
        mealReasons[Self.reasonKey(person: person, day: day, mealType: mealType)] ?? ""
    }

    private static func quickMealKey(day: DayOfWeek, mealType: MealType) -> String {
        "\(day.rawValue)-\(mealType.rawValue)"
    }

    func setQuickMeal(_ isQuick: Bool, for day: DayOfWeek, mealType: MealType) {
        let key = Self.quickMealKey(day: day, mealType: mealType)
        quickMeals[key] = isQuick
    }

    func isQuickMeal(for day: DayOfWeek, mealType: MealType) -> Bool {
        quickMeals[Self.quickMealKey(day: day, mealType: mealType)] ?? false
    }
}
