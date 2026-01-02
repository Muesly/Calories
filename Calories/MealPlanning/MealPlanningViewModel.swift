//
//  MealPlanningViewModel.swift
//  Calories
//
//  Created by Tony Short on 08/07/2025.
//

import Foundation
import SwiftData

enum MealPlanError: LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save meal plan: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load meal plan: \(error.localizedDescription)"
        }
    }
}

enum Person: String, CaseIterable {
    case tony = "Tony"
    case karen = "Karen"
}

/// Type-safe key for person-specific meal data
struct PersonMealKey: Hashable {
    let person: Person
    let date: Date
    let mealType: MealType

    func normalize() -> PersonMealKey {
        PersonMealKey(
            person: person,
            date: Calendar.current.startOfDay(for: date),
            mealType: mealType
        )
    }
}

/// Type-safe key for meal-level data (shared across people)
struct MealKey: Hashable {
    let date: Date
    let mealType: MealType

    func normalize() -> MealKey {
        MealKey(
            date: Calendar.current.startOfDay(for: date),
            mealType: mealType
        )
    }
}

struct MealSelection {
    var person: Person
    var date: Date
    var mealType: MealType
    var isSelected: Bool
    var recipe: RecipeEntry?

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

@Observable
@MainActor
class MealPlanningViewModel: ObservableObject {
    let modelContext: ModelContext
    var currentStage: WizardStage = .mealPicking
    var mealSelections: [MealSelection] = []
    var mealReasons: [PersonMealKey: String] = [:]
    var quickMeals: [MealKey: Bool] = [:]
    var foodToUseUp: [FoodToUseUp] = []
    var lastError: MealPlanError?
    let mealPickerEngine: MealPickerEngine
    let weekDates: [Date]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.mealPickerEngine = MealPickerEngine(recipes: modelContext.recipeResults())

        let calendar = Calendar.current
        self.weekDates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: Self.startOfPlanningWeek())
        }

        for person in Person.allCases {
            for date in weekDates {
                for mealType in MealType.allCases {
                    mealSelections.append(
                        .init(person: person, date: date, mealType: mealType, isSelected: true))
                }
            }
        }

        currentStage = AppFlags.showRecipeShortcut ? .mealPicking : .mealAvailability
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

    func fetchRecipes() {
        populateMealRecipes(onlyEmpty: false)
    }

    // MARK: - Private Helpers

    /// Checks if a meal selection matches the given criteria
    private func matchesMeal(
        selection: MealSelection, person: Person, date: Date, mealType: MealType
    ) -> Bool {
        selection.person == person && date.isSameDay(as: selection.date)
            && selection.mealType == mealType
    }

    /// Finds the index of a meal selection matching the given criteria
    private func findMealSelectionIndex(
        for person: Person, date: Date, mealType: MealType
    ) -> Int? {
        mealSelections.firstIndex { selection in
            matchesMeal(selection: selection, person: person, date: date, mealType: mealType)
        }
    }

    /// Finds the meal selection matching the given criteria
    private func findMealSelection(
        for person: Person, date: Date, mealType: MealType
    ) -> MealSelection? {
        mealSelections.first { selection in
            matchesMeal(selection: selection, person: person, date: date, mealType: mealType)
        }
    }

    /// Generates a storage key for meal-level data (not person-specific)
    private static func mealKey(date: Date, mealType: MealType) -> MealKey {
        MealKey(date: date, mealType: mealType).normalize()
    }

    // MARK: - Meal Selection

    func toggleMealSelection(for person: Person, date: Date, mealType: MealType) {
        guard let index = findMealSelectionIndex(for: person, date: date, mealType: mealType) else {
            return
        }
        mealSelections[index].isSelected.toggle()
    }

    func isSelected(for person: Person, date: Date, mealType: MealType) -> Bool {
        return findMealSelection(for: person, date: date, mealType: mealType)?.isSelected ?? false
    }

    // MARK: - Meal Reasons

    func setReason(_ reason: String, for person: Person, date: Date, mealType: MealType) {
        let key = PersonMealKey(person: person, date: date, mealType: mealType).normalize()
        if reason.isEmpty {
            mealReasons.removeValue(forKey: key)
        } else {
            mealReasons[key] = reason
        }
    }

    func getReason(for person: Person, date: Date, mealType: MealType) -> String {
        let key = PersonMealKey(person: person, date: date, mealType: mealType).normalize()
        return mealReasons[key] ?? ""
    }

    // MARK: - Quick Meals

    func setQuickMeal(_ isQuick: Bool, for date: Date, mealType: MealType) {
        let key = Self.mealKey(date: date, mealType: mealType)
        quickMeals[key] = isQuick
    }

    func isQuickMeal(for date: Date, mealType: MealType) -> Bool {
        let key = Self.mealKey(date: date, mealType: mealType)
        return quickMeals[key] ?? false
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

    func meal(forDate date: Date, mealType: MealType) -> MealSelection? {
        mealSelections.first { $0.mealType == mealType && $0.date.isSameDay(as: date) }
    }

    func selectRecipe(_ recipe: RecipeEntry, for person: Person, date: Date, mealType: MealType) {
        guard let index = findMealSelectionIndex(for: person, date: date, mealType: mealType) else {
            return
        }
        mealSelections[index].recipe = recipe
    }

    func populateEmptyMeals() {
        populateMealRecipes(onlyEmpty: true)
    }

    /// Populates meal recipes using the picker engine
    /// - Parameter onlyEmpty: If true, only fills meals without recipes; if false, fills all
    private func populateMealRecipes(onlyEmpty: Bool) {
        // Build a cache of recipes per date+mealType to ensure consistency
        var recipeCache: [MealKey: RecipeEntry?] = [:]

        for index in mealSelections.indices {
            let selection = mealSelections[index]

            // Skip if only populating empty meals and this one has a recipe
            if onlyEmpty && selection.recipe != nil {
                continue
            }

            let key = Self.mealKey(date: selection.date, mealType: selection.mealType)

            // Only pick a recipe if at least one person is attending
            if recipeCache[key] == nil {
                let count = attendeeCount(for: selection.date, mealType: selection.mealType)
                if count > 0 {
                    recipeCache[key] = mealPickerEngine.pickRecipe(mealType: selection.mealType)
                } else {
                    recipeCache[key] = .some(nil)  // Mark as processed but no recipe
                }
            }

            mealSelections[index].recipe = recipeCache[key] ?? nil
        }
    }

    func swapMeals(_ meal1: MealSelection, with meal2: MealSelection) {
        let meal1Index = mealSelections.firstIndex { $0.id == meal1.id }
        let meal2Index = mealSelections.firstIndex { $0.id == meal2.id }

        guard let idx1 = meal1Index, let idx2 = meal2Index else { return }

        let tempRecipe = mealSelections[idx1].recipe
        mealSelections[idx1].recipe = mealSelections[idx2].recipe
        mealSelections[idx2].recipe = tempRecipe
    }

    // MARK: - Serving Info

    /// Returns the number of people attending a meal
    func attendeeCount(for date: Date, mealType: MealType) -> Int {
        Person.allCases.filter { isSelected(for: $0, date: date, mealType: mealType) }.count
    }

    /// Returns serving info text for display in meal picker
    func servingInfo(for date: Date, mealType: MealType) -> String {
        let count = attendeeCount(for: date, mealType: mealType)
        let absentPeople = Person.allCases.filter {
            !isSelected(for: $0, date: date, mealType: mealType)
        }

        switch count {
        case 2:
            return "2 x servings"
        case 1:
            if let absentPerson = absentPeople.first {
                let reason = getReason(for: absentPerson, date: date, mealType: mealType)
                let reasonText = reason.isEmpty ? "" : " - \(reason)"
                return "1 x serving (\(absentPerson.rawValue)\(reasonText))"
            }
            return "1 x serving"
        case 0:
            let reasonsByPerson = absentPeople.map { person -> (Person, String) in
                (person, getReason(for: person, date: date, mealType: mealType))
            }

            // Check if all reasons are the same
            let uniqueReasons = Set(reasonsByPerson.map { $0.1 })
            let allReasonsSame = uniqueReasons.count <= 1

            let reasonText: String
            if allReasonsSame {
                // All have the same reason (or all empty), omit person names
                let reasons = reasonsByPerson.compactMap { $0.1.isEmpty ? nil : $0.1 }
                reasonText = reasons.isEmpty ? "" : " - \(reasons.joined(separator: ", "))"
            } else {
                // Reasons differ, include person names
                let reasons = reasonsByPerson.compactMap { person, reason -> String? in
                    reason.isEmpty ? nil : "\(person.rawValue): \(reason)"
                }
                reasonText = reasons.isEmpty ? "" : " - \(reasons.joined(separator: ", "))"
            }

            return "No meal required\(reasonText)"
        default:
            return "\(count) x servings"
        }
    }

    /// Returns the Monday to plan from:
    /// - Mon-Wed: this week's Monday
    /// - Thu-Sun: next week's Monday
    static func startOfPlanningWeek(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        // Calendar weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // Monday = 2, Tuesday = 3, Wednesday = 4
        let isEarlyInWeek = (2...4).contains(weekday)

        // Find this week's Monday
        let thisMonday = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!

        if isEarlyInWeek {
            return thisMonday
        } else {
            // Return next Monday
            return calendar.date(byAdding: .weekOfYear, value: 1, to: thisMonday)!
        }
    }

    // MARK: - Persistence

    private var weekStartDate: Date {
        Self.startOfPlanningWeek()
    }

    func loadMealPlan() {
        let entry = MealPlanEntry.findOrCreate(for: weekStartDate, in: modelContext)

        // Load recipes for converting stored selections
        let recipes = modelContext.recipeResults()

        // Load meal selections
        let storedSelections = entry.getMealSelections(recipes: recipes)
        if !storedSelections.isEmpty {
            // Update existing selections with stored recipes
            for storedSelection in storedSelections {
                if let index = mealSelections.firstIndex(where: {
                    $0.person == storedSelection.person
                        && $0.date.isSameDay(as: storedSelection.date)
                        && $0.mealType == storedSelection.mealType
                }) {
                    mealSelections[index].isSelected = storedSelection.isSelected
                    mealSelections[index].recipe = storedSelection.recipe
                }
            }
        }

        // Load meal reasons
        mealReasons = entry.getMealReasons()

        // Load quick meals
        quickMeals = entry.getQuickMeals()

        // Load food to use up
        foodToUseUp = entry.getFoodToUseUp()

        // Clear any previous errors
        lastError = nil
    }

    func saveMealPlan() {
        do {
            let entry = MealPlanEntry.findOrCreate(for: weekStartDate, in: modelContext)

            // Save meal selections
            entry.setMealSelections(mealSelections)

            // Save meal reasons
            entry.setMealReasons(mealReasons)

            // Save quick meals
            entry.setQuickMeals(quickMeals)

            // Save food to use up
            entry.setFoodToUseUp(foodToUseUp)

            try modelContext.save()
            print("✓ Meal plan saved successfully")

            // Clear any previous errors
            lastError = nil
        } catch {
            lastError = .saveFailed(error)
            print("✗ Error saving meal plan: \(error)")
        }
    }
}
