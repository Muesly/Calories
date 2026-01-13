//
//  MealPlanningViewModel.swift
//  Calories
//
//  Created by Tony Short on 08/07/2025.
//

import Foundation
import SwiftData

// MARK: - View Model

@Observable
@MainActor
class MealPlanningViewModel: ObservableObject {
    private enum MealPlanError: LocalizedError {
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

    let modelContext: ModelContext
    var mealSelections: [MealSelection] = []
    var mealReasons: [PersonMealKey: String] = [:]
    var quickMeals: [MealKey: Bool] = [:]
    var pinnedMeals: [MealKey: Bool] = [:]
    var foodToUseUp: [FoodToUseUp] = []
    private var lastError: MealPlanError?
    let mealPickerEngine: MealPickerEngine
    var currentWeekStartDate: Date
    var weekDates: [Date]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.mealPickerEngine = MealPickerEngine(recipes: modelContext.recipeResults())

        let startDate = Self.startOfPlanningWeek()
        self.currentWeekStartDate = startDate

        let calendar = Calendar.current
        self.weekDates = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }

        for person in Person.allCases {
            for date in weekDates {
                for mealType in MealType.allCases {
                    mealSelections.append(
                        .init(
                            person: person,
                            dayMeal: DayMeal(mealType: mealType, date: date),
                            isSelected: true))
                }
            }
        }
    }

    func fetchRecipes() {
        populateMealRecipes(onlyEmpty: false)
    }

    // MARK: - Private Helpers

    /// Checks if a meal selection matches the given criteria
    private func matchesMeal(
        selection: MealSelection, person: Person, dayMeal: DayMeal
    ) -> Bool {
        selection.person == person && dayMeal == selection.dayMeal
    }

    /// Finds the index of a meal selection matching the given criteria
    private func findMealSelectionIndex(
        for person: Person, dayMeal: DayMeal
    ) -> Int? {
        mealSelections.firstIndex { selection in
            matchesMeal(selection: selection, person: person, dayMeal: dayMeal)
        }
    }

    /// Finds the meal selection matching the given criteria
    private func findMealSelection(
        for person: Person, dayMeal: DayMeal
    ) -> MealSelection? {
        mealSelections.first { selection in
            matchesMeal(selection: selection, person: person, dayMeal: dayMeal)
        }
    }

    /// Generates a storage key for meal-level data (not person-specific)
    private static func mealKey(dayMeal: DayMeal) -> MealKey {
        MealKey(dayMeal: dayMeal).normalize()
    }

    // MARK: - Meal Selection

    func toggleMealSelection(for person: Person, dayMeal: DayMeal) {
        guard let index = findMealSelectionIndex(for: person, dayMeal: dayMeal) else {
            return
        }
        mealSelections[index].isSelected.toggle()
        saveMealPlan()
    }

    func isSelected(for person: Person, dayMeal: DayMeal) -> Bool {
        findMealSelection(for: person, dayMeal: dayMeal)?.isSelected ?? false
    }

    // MARK: - Meal Reasons

    func setReason(_ reason: String, for person: Person, dayMeal: DayMeal) {
        let key = PersonMealKey(person: person, dayMeal: dayMeal)
            .normalize()
        if reason.isEmpty {
            mealReasons.removeValue(forKey: key)
        } else {
            mealReasons[key] = reason
        }
        saveMealPlan()
    }

    func getReason(for person: Person, dayMeal: DayMeal) -> String {
        let key = PersonMealKey(person: person, dayMeal: dayMeal)
            .normalize()
        return mealReasons[key] ?? ""
    }

    // MARK: - Quick Meals

    func setQuickMeal(_ isQuick: Bool, dayMeal: DayMeal) {
        let key = Self.mealKey(dayMeal: dayMeal)
        quickMeals[key] = isQuick
        saveMealPlan()
    }

    func isQuickMeal(forDayMeal dayMeal: DayMeal) -> Bool {
        let key = Self.mealKey(dayMeal: dayMeal)
        return quickMeals[key] ?? false
    }

    // MARK: - Pinned Meals

    func setPinnedMeal(_ isPinned: Bool, dayMeal: DayMeal) {
        let key = Self.mealKey(dayMeal: dayMeal)
        pinnedMeals[key] = isPinned
        saveMealPlan()
    }

    func isPinnedMeal(forDayMeal dayMeal: DayMeal) -> Bool {
        let key = Self.mealKey(dayMeal: dayMeal)
        return pinnedMeals[key] ?? false
    }

    // MARK: - Food To Use Up

    func addFoodItem() {
        foodToUseUp.append(FoodToUseUp())
        saveMealPlan()
    }

    func removeFoodItem(withId id: UUID) {
        foodToUseUp.removeAll { $0.id == id }
        saveMealPlan()
    }

    func updateFoodItem(_ item: FoodToUseUp) {
        if let index = foodToUseUp.firstIndex(where: { $0.id == item.id }) {
            foodToUseUp[index] = item
            saveMealPlan()
        }
    }

    func meals(forDayMeal dayMeal: DayMeal) -> [MealSelection] {
        // Can be multiple if not all having same meal
        mealSelections.filter { dayMeal == $0.dayMeal }
    }

    func selectRecipe(_ recipe: RecipeEntry, for person: Person, dayMeal: DayMeal) {
        guard let index = findMealSelectionIndex(for: person, dayMeal: dayMeal) else {
            return
        }
        mealSelections[index].recipe = recipe
        saveMealPlan()
    }

    func clearMeal(for person: Person, dayMeal: DayMeal) {
        guard let index = findMealSelectionIndex(for: person, dayMeal: dayMeal) else {
            return
        }
        mealSelections[index].recipe = nil
        saveMealPlan()
    }

    func populateEmptyMeals() {
        populateMealRecipes(onlyEmpty: false)
        saveMealPlan()
    }

    /// Populates meal recipes using the picker engine
    /// - Parameter onlyEmpty: If true, only fills meals without recipes; if false, fills all
    private func populateMealRecipes(onlyEmpty: Bool) {
        // Build a cache of recipes per date+mealType to ensure consistency
        var recipeCache: [MealKey: RecipeEntry?] = [:]

        // Track used recipes for variety consideration
        var usedRecipes: [(dayMeal: DayMeal, recipe: RecipeEntry)] = []

        // Get unique meal keys sorted by date and meal type for chronological processing
        let uniqueMealKeys = Array(
            Set(
                mealSelections.map {
                    Self.mealKey(dayMeal: $0.dayMeal)
                })
        ).sorted()

        // Process each unique meal in chronological order
        for key in uniqueMealKeys {
            // Find a selection for this meal key
            guard
                let selection = mealSelections.first(where: {
                    Self.mealKey(dayMeal: $0.dayMeal) == key
                })
            else {
                continue
            }

            // Skip if meal is pinned
            if isPinnedMeal(forDayMeal: selection.dayMeal) {
                // Keep existing recipe in used recipes if it exists
                if let existingRecipe = selection.recipe {
                    usedRecipes.append(
                        (dayMeal: selection.dayMeal, recipe: existingRecipe)
                    )
                }
                continue
            }

            // Skip if only populating empty meals and this one has a recipe
            if onlyEmpty && selection.recipe != nil {
                // Keep existing recipe in used recipes
                if let existingRecipe = selection.recipe {
                    usedRecipes.append(
                        (dayMeal: selection.dayMeal, recipe: existingRecipe)
                    )
                }
                continue
            }

            // Only pick a recipe if at least one person is attending
            let count = attendeeCount(forDayMeal: selection.dayMeal)
            if count > 0 {
                if let recipe = mealPickerEngine.pickRecipe(
                    dayMeal: selection.dayMeal,
                    usedRecipes: usedRecipes
                ) {
                    recipeCache[key] = recipe
                    usedRecipes.append(
                        (dayMeal: selection.dayMeal, recipe: recipe))
                } else {
                    recipeCache[key] = .some(nil)
                }
            } else {
                recipeCache[key] = .some(nil)  // Mark as processed but no recipe
            }
        }

        // Apply the cached recipes to all matching selections
        for index in mealSelections.indices {
            let selection = mealSelections[index]
            let key = Self.mealKey(dayMeal: selection.dayMeal)
            if let cachedRecipe = recipeCache[key] {
                mealSelections[index].recipe = cachedRecipe
            }
        }
    }

    func swapMeals(_ dayMeal1: DayMeal, with dayMeal2: DayMeal) {
        // Swap recipes between the same person's meals on different days or different meal types
        // Get the first person's meals for each day/meal type (prioritize same person)
        guard
            let meal1 = mealSelections.first(where: {
                $0.dayMeal == dayMeal1
            }),
            let meal2 = mealSelections.first(where: {
                $0.dayMeal == dayMeal2
            })
        else {
            return
        }
        swapMeals(meal1, with: meal2)
    }

    private func swapMeals(_ meal1: MealSelection, with meal2: MealSelection) {
        let meal1Index = mealSelections.firstIndex { $0.id == meal1.id }
        let meal2Index = mealSelections.firstIndex { $0.id == meal2.id }

        guard let idx1 = meal1Index, let idx2 = meal2Index else { return }

        let tempRecipe = mealSelections[idx1].recipe
        mealSelections[idx1].recipe = mealSelections[idx2].recipe
        mealSelections[idx2].recipe = tempRecipe
        saveMealPlan()
    }

    // MARK: - Serving Info

    /// Returns the number of people attending a meal
    func attendeeCount(forDayMeal dayMeal: DayMeal) -> Int {
        Person.allCases.filter { isSelected(for: $0, dayMeal: dayMeal) }.count
    }

    /// Returns serving info text for display in meal picker
    func servingInfo(forDayMeal dayMeal: DayMeal) -> String {
        let count = attendeeCount(forDayMeal: dayMeal)
        let absentPeople = Person.allCases.filter {
            !isSelected(for: $0, dayMeal: dayMeal)
        }

        switch count {
        case 2:
            return "2 x servings"
        case 1:
            if let presentPerson = Person.allCases.first(where: {
                isSelected(for: $0, dayMeal: dayMeal)
            }) {
                return "1 x serving (\(presentPerson.rawValue))"
            }
            return "1 x serving"
        case 0:
            let reasonsByPerson = absentPeople.map { person -> (Person, String) in
                (person, getReason(for: person, dayMeal: dayMeal))
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

    // MARK: - Week Navigation

    func goToPreviousWeek() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStartDate) {
            currentWeekStartDate = newDate
            weekDates = (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: newDate)
            }
            loadMealPlan()
        }
    }

    func goToNextWeek() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStartDate) {
            currentWeekStartDate = newDate
            weekDates = (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: newDate)
            }
            loadMealPlan()
        }
    }

    // MARK: - Persistence

    private var weekStartDate: Date {
        currentWeekStartDate
    }

    func loadMealPlan() {
        let entry = MealPlanEntry.findOrCreate(for: weekStartDate, in: modelContext)

        // Load recipes for converting stored selections
        let recipes = modelContext.recipeResults()

        // Recreate mealSelections array with current week's dates
        mealSelections = []
        for person in Person.allCases {
            for date in weekDates {
                for mealType in MealType.allCases {
                    mealSelections.append(
                        MealSelection(
                            person: person,
                            dayMeal: DayMeal(mealType: mealType, date: date),
                            isSelected: true))
                }
            }
        }

        // Load meal selections
        let storedSelections = entry.getMealSelections(recipes: recipes)
        if !storedSelections.isEmpty {
            // Update existing selections with stored recipes
            for storedSelection in storedSelections {
                if let index = mealSelections.firstIndex(where: {
                    $0.person == storedSelection.person && $0.dayMeal == storedSelection.dayMeal
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

        // Load pinned meals
        pinnedMeals = entry.getPinnedMeals()

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

            // Save pinned meals
            entry.setPinnedMeals(pinnedMeals)

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
