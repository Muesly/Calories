//
//  MealPlanningViewModelTests.swift
//  CaloriesTests
//
//  Created by Claude Code on 22/12/2025.
//

import Foundation
import SwiftData
import Testing

@testable import Calories

@Suite("MealPlanningViewModel")
@MainActor
struct MealPlanningViewModelTests {
    var subject: MealPlanningViewModel
    var modelContext: ModelContext! = .inMemory

    init() {
        subject = MealPlanningViewModel(
            modelContext: modelContext,
            startDate: .testReference.startOfPlanningWeek
        )
    }

    // MARK: - Attendee Count Tests

    @Test("Attendee count when both present")
    func attendeeCountWhenBothPresent() {
        let dayMeal = DayMeal(mealType: .breakfast, date: Date.testReference.startOfPlanningWeek)
        #expect(subject.attendeeCount(forDayMeal: dayMeal) == 2)
    }

    @Test("Attendee count when one absent")
    func attendeeCountWhenOneAbsent() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        #expect(subject.attendeeCount(forDayMeal: dayMeal) == 1)
    }

    @Test("Attendee count when both absent")
    func attendeeCountWhenBothAbsent() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .karen, dayMeal: dayMeal)
        #expect(subject.attendeeCount(forDayMeal: dayMeal) == 0)
    }

    // MARK: - Serving Info Tests

    @Test("Serving info when both present")
    func servingInfoWhenBothPresent() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        let info = subject.servingInfo(forDayMeal: dayMeal)
        #expect(info == "2 x servings")
    }

    @Test("Serving info when one absent with reason")
    func servingInfoWhenOneAbsentWithReason() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.setReason("Working late", for: .tony, dayMeal: dayMeal)
        #expect(subject.servingInfo(forDayMeal: dayMeal) == "1 x serving (Karen)")
        #expect(subject.getReason(for: .tony, dayMeal: dayMeal) == "Working late")
    }

    @Test("Serving info when one absent without reason")
    func servingInfoWhenOneAbsentWithoutReason() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        #expect(subject.servingInfo(forDayMeal: dayMeal) == "1 x serving (Karen)")
        #expect(subject.getReason(for: .tony, dayMeal: dayMeal) == "")
    }

    @Test("Serving info when both absent with same reason")
    func servingInfoWhenBothAbsentSameReason() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .karen, dayMeal: dayMeal)
        subject.setReason("Out of town", for: .tony, dayMeal: dayMeal)
        subject.setReason("Out of town", for: .karen, dayMeal: dayMeal)
        #expect(subject.servingInfo(forDayMeal: dayMeal) == "No meal required - Out of town")
    }

    @Test("Serving info when both absent with different reasons")
    func servingInfoWhenBothAbsentDifferentReasons() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .karen, dayMeal: dayMeal)
        subject.setReason("Working late", for: .tony, dayMeal: dayMeal)
        subject.setReason("Doctor appointment", for: .karen, dayMeal: dayMeal)
        #expect(
            subject.servingInfo(forDayMeal: dayMeal)
                == "No meal required - Tony: Working late, Karen: Doctor appointment")
    }

    @Test("Serving info when both absent with no reasons")
    func servingInfoWhenBothAbsentNoReasons() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .karen, dayMeal: dayMeal)
        #expect(subject.servingInfo(forDayMeal: dayMeal) == "No meal required")
    }

    @Test("Serving info when both absent with one reason")
    func servingInfoWhenBothAbsentOneWithReason() {
        let dayMeal = DayMeal(mealType: .breakfast, date: .testReference.startOfPlanningWeek)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .karen, dayMeal: dayMeal)
        subject.setReason("Traveling", for: .tony, dayMeal: dayMeal)
        #expect(subject.servingInfo(forDayMeal: dayMeal) == "No meal required - Traveling")
    }

    // MARK: - populateEmptyMeals Tests

    @Test("Fetch recipes picks recipe when at least one person present")
    func populateEmptyMealsPicksRecipeWhenAtLeastOnePersonPresent() {
        RecipeEntry.seedRecipes(into: modelContext)
        let recipes = modelContext.recipeResults()

        subject.populateMealRecipes()
        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        let meals = subject.meals(forDayMeal: dayMeal)

        #expect(meals.first?.recipe != nil)
    }

    @Test("Fetch recipes does not pick recipe when both absent")
    func populateEmptyMealsDoesNotPickRecipeWhenBothAbsent() {
        RecipeEntry.seedRecipes(into: modelContext)

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .karen, dayMeal: dayMeal)

        subject.populateMealRecipes()

        let mealTony = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        let mealKaren = subject.mealSelections.first {
            $0.person == .karen && $0.dayMeal == dayMeal
        }

        #expect(mealTony?.recipe == nil)
        #expect(mealKaren?.recipe == nil)
    }

    @Test("Fetch recipes picks same recipe for both people")
    func populateEmptyMealsPicksSameRecipeForBothPeople() {
        RecipeEntry.seedRecipes(into: modelContext)
        subject.populateMealRecipes()

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        let mealTony = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        let mealKaren = subject.mealSelections.first {
            $0.person == .karen && $0.dayMeal == dayMeal
        }

        #expect(mealTony?.recipe?.name == mealKaren?.recipe?.name)
    }

    // MARK: - startOfPlanningWeek Tests

    @Test("Start of planning week")
    func startOfPlanningWeek() {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.weekday, .day]

        // Monday to Wednesday we are still planning for current week
        let monday = Date.testReference.startOfWeek
        let mondayResult = calendar.dateComponents(components, from: monday.startOfPlanningWeek)
        #expect(mondayResult.weekday == 2)
        #expect(mondayResult.day == 29)

        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let tuesdayResult = calendar.dateComponents(components, from: tuesday.startOfPlanningWeek)
        #expect(tuesdayResult.weekday == 2)
        #expect(tuesdayResult.day == 29)

        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!
        let wednesdayResult = calendar.dateComponents(
            components, from: wednesday.startOfPlanningWeek)
        #expect(wednesdayResult.weekday == 2)
        #expect(wednesdayResult.day == 29)

        // Thursday onwards we are planning the following week
        let thursday = calendar.date(byAdding: .day, value: 3, to: monday)!
        let thursdayResult = calendar.dateComponents(components, from: thursday.startOfPlanningWeek)
        #expect(thursdayResult.weekday == 2)
        #expect(thursdayResult.day == 5)

        let friday = calendar.date(byAdding: .day, value: 4, to: monday)!
        let fridayResult = calendar.dateComponents(components, from: friday.startOfPlanningWeek)
        #expect(fridayResult.weekday == 2)
        #expect(fridayResult.day == 5)

        let saturday = calendar.date(byAdding: .day, value: 5, to: monday)!
        let saturdayResult = calendar.dateComponents(components, from: saturday.startOfPlanningWeek)
        #expect(saturdayResult.weekday == 2)
        #expect(saturdayResult.day == 5)

        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        let sundayResult = calendar.dateComponents(components, from: sunday.startOfPlanningWeek)
        #expect(sundayResult.weekday == 2)
        #expect(sundayResult.day == 5)
    }

    // MARK: - Swap Meals Tests

    @Test("Swap meals exchanges recipes")
    func swapMealsExchangesRecipes() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard recipes.count >= 2 else {
            Issue.record("Not enough recipes for swap test")
            return
        }

        let date = subject.weekDates[0]
        let mealType1 = MealType.breakfast
        let mealType2 = MealType.lunch
        let dayMeal1 = DayMeal(mealType: mealType1, date: date)
        let dayMeal2 = DayMeal(mealType: mealType2, date: date)

        subject.selectRecipe(recipes[0], for: .tony, dayMeal: dayMeal1)
        subject.selectRecipe(recipes[1], for: .tony, dayMeal: dayMeal2)

        subject.swapMeals(dayMeal1, with: dayMeal2)

        let swappedMeal1 = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal1
        }!
        let swappedMeal2 = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal2
        }!

        #expect(swappedMeal1.recipe?.name == recipes[1].name)
        #expect(swappedMeal2.recipe?.name == recipes[0].name)
    }

    // MARK: - Food To Use Up Tests

    @Test("Add food item appends to list")
    func addFoodItemAppends() {
        let initialCount = subject.foodToUseUp.count

        subject.addFoodItem()

        #expect(subject.foodToUseUp.count == initialCount + 1)
    }

    @Test("Remove food item by index")
    func removeFoodItemByIndex() {
        subject.addFoodItem()
        subject.addFoodItem()
        let countBefore = subject.foodToUseUp.count
        let firstItemId = subject.foodToUseUp[0].id

        subject.removeFoodItem(withId: firstItemId)

        #expect(subject.foodToUseUp.count == countBefore - 1)
    }

    @Test("Remove food item by id")
    func removeFoodItemById() {
        subject.addFoodItem()
        let item = subject.foodToUseUp[0]

        subject.removeFoodItem(withId: item.id)

        #expect(subject.foodToUseUp.isEmpty)
    }

    @Test("Update food item")
    func updateFoodItem() {
        subject.addFoodItem()
        let item = subject.foodToUseUp[0]
        var updatedItem = item
        updatedItem.name = "Updated Food"

        subject.updateFoodItem(updatedItem)

        #expect(subject.foodToUseUp[0].name == "Updated Food")
    }

    // MARK: - Persistence Tests

    @Test("Load and save meal plan preserves selections")
    func loadAndSaveMealPlanPreservesSelections() {
        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.saveMealPlan()

        let subject2 = MealPlanningViewModel(modelContext: modelContext, startDate: date)
        subject2.loadMealPlan()

        #expect(!subject2.isSelected(for: .tony, dayMeal: dayMeal))
    }

    @Test("Load and save meal plan preserves reasons")
    func loadAndSaveMealPlanPreservesReasons() {
        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        subject.setReason("Working late", for: .tony, dayMeal: dayMeal)
        subject.saveMealPlan()

        let subject2 = MealPlanningViewModel(modelContext: modelContext, startDate: date)
        subject2.loadMealPlan()

        #expect(subject2.getReason(for: .tony, dayMeal: dayMeal) == "Working late")
    }

    @Test("Load and save meal plan preserves quick meals")
    func loadAndSaveMealPlanPreservesQuickMeals() {
        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        subject.setQuickMeal(true, dayMeal: dayMeal)
        subject.saveMealPlan()

        let subject2 = MealPlanningViewModel(modelContext: modelContext, startDate: date)
        subject2.loadMealPlan()

        #expect(subject2.isQuickMeal(forDayMeal: dayMeal))
    }

    @Test("Load and save meal plan preserves food to use up")
    func loadAndSaveMealPlanPreservesFoodToUseUp() throws {
        subject.addFoodItem()
        var item = subject.foodToUseUp[0]
        item.name = "Leftover pasta"
        subject.updateFoodItem(item)
        subject.saveMealPlan()

        let subject2 = MealPlanningViewModel(
            modelContext: modelContext,
            startDate: Date.testReference.startOfPlanningWeek)
        subject2.loadMealPlan()

        #expect(subject2.foodToUseUp.count == 1)
        let firstFoodToUseUp = try #require(subject2.foodToUseUp.first?.name)
        #expect(firstFoodToUseUp == "Leftover pasta")
    }

    // MARK: - Recipe Selection Tests

    @Test("Select recipe assigns recipe to person's meal")
    func selectRecipeAssignsToMeal() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let recipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(recipe, for: .tony, dayMeal: dayMeal)

        let meal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        #expect(meal?.recipe?.name == recipe.name)
    }

    @Test("Remove meal clears recipe for all people at day meal")
    func removeMealClearsRecipeForAllPeople() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let recipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(recipe, for: .tony, dayMeal: dayMeal)
        subject.selectRecipe(recipe, for: .karen, dayMeal: dayMeal)

        subject.removeMeal(forDayMeal: dayMeal)

        let tonyMeal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        let karenMeal = subject.mealSelections.first {
            $0.person == .karen && $0.dayMeal == dayMeal
        }

        #expect(tonyMeal?.recipe == nil)
        #expect(karenMeal?.recipe == nil)
    }

    // MARK: - Split and Join Meal Tests

    @Test("Split meal clears Karen's recipe")
    func splitMealClearsKarensRecipe() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let recipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(recipe, for: .tony, dayMeal: dayMeal)
        subject.selectRecipe(recipe, for: .karen, dayMeal: dayMeal)

        subject.splitMeal(dayMeal: dayMeal)

        let tonyMeal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        let karenMeal = subject.mealSelections.first {
            $0.person == .karen && $0.dayMeal == dayMeal
        }

        #expect(tonyMeal?.recipe?.name == recipe.name)
        #expect(karenMeal?.recipe == nil)
    }

    @Test("Join meal copies Tony's recipe to Karen")
    func joinMealCopiesRecipe() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard recipes.count >= 2 else {
            Issue.record("Need at least 2 recipes")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(recipes[0], for: .tony, dayMeal: dayMeal)
        subject.selectRecipe(recipes[1], for: .karen, dayMeal: dayMeal)

        subject.joinMeal(dayMeal: dayMeal)

        let tonyMeal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        let karenMeal = subject.mealSelections.first {
            $0.person == .karen && $0.dayMeal == dayMeal
        }

        #expect(tonyMeal?.recipe?.name == recipes[0].name)
        #expect(karenMeal?.recipe?.name == recipes[0].name)
    }

    // MARK: - Pinned Meal Tests

    @Test("Set pinned meal stores pinned status")
    func setPinnedMealStoresStatus() {
        let date = subject.weekDates[0]
        let mealType = MealType.lunch
        let dayMeal = DayMeal(mealType: mealType, date: date)

        subject.setPinnedMeal(true, dayMeal: dayMeal)

        #expect(subject.isPinnedMeal(forDayMeal: dayMeal))
    }

    @Test("Pinned meals are not replaced when fetching recipes")
    func pinnedMealsAreNotReplaced() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let recipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(recipe, for: .tony, dayMeal: dayMeal)
        subject.setPinnedMeal(true, dayMeal: dayMeal)

        subject.populateMealRecipes()

        let meal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }

        #expect(meal?.recipe?.name == recipe.name)
    }

    @Test("Unpinned meals can be replaced when fetching recipes")
    func unpinnedMealsCanBeReplaced() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let firstRecipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(firstRecipe, for: .tony, dayMeal: dayMeal)
        subject.setPinnedMeal(false, dayMeal: dayMeal)

        subject.populateMealRecipes()

        let meal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }

        #expect(meal?.recipe != nil)
    }

    // MARK: - Week Navigation Tests

    @Test("Go to previous week changes week dates")
    func goToPreviousWeekChangesWeekDates() {
        let originalStartDate = subject.currentWeekStartDate
        let originalFirstDate = subject.weekDates.first!

        subject.goToPreviousWeek()

        #expect(subject.currentWeekStartDate < originalStartDate)
        #expect(subject.weekDates.first! < originalFirstDate)
        #expect(subject.weekDates.count == 7)
    }

    @Test("Go to next week changes week dates")
    func goToNextWeekChangesWeekDates() {

        let originalStartDate = subject.currentWeekStartDate
        let originalFirstDate = subject.weekDates.first!

        subject.goToNextWeek()

        #expect(subject.currentWeekStartDate > originalStartDate)
        #expect(subject.weekDates.first! > originalFirstDate)
        #expect(subject.weekDates.count == 7)
    }

    @Test("Week navigation loads meal plan for new week")
    func weekNavigationLoadsMealPlan() {
        RecipeEntry.seedRecipes(into: modelContext)

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.saveMealPlan()

        subject.goToNextWeek()
        subject.goToPreviousWeek()

        let isSelected = subject.isSelected(for: .tony, dayMeal: dayMeal)
        #expect(!isSelected)
    }

    // MARK: - Meals Retrieval Tests

    @Test("Meals returns all meal selections for day meal")
    func mealsReturnsAllSelectionsForDayMeal() {
        let date = subject.weekDates[0]
        let mealType = MealType.dinner
        let dayMeal = DayMeal(mealType: mealType, date: date)

        let meals = subject.meals(forDayMeal: dayMeal)

        #expect(meals.count == Person.allCases.count)
        #expect(meals.allSatisfy { $0.dayMeal == dayMeal })
    }

    // MARK: - Persistence with Pinned Meals Tests

    @Test("Load and save meal plan preserves pinned meals")
    func loadAndSaveMealPlanPreservesPinnedMeals() {
        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .dinner, date: date)
        subject.setPinnedMeal(true, dayMeal: dayMeal)
        subject.saveMealPlan()

        let subject2 = MealPlanningViewModel(modelContext: modelContext, startDate: date)
        subject2.loadMealPlan()

        let isPinned = subject2.isPinnedMeal(forDayMeal: dayMeal)
        #expect(isPinned)
    }

    @Test("Load and save meal plan preserves recipes")
    func loadAndSaveMealPlanPreservesRecipes() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let recipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)
        subject.selectRecipe(recipe, for: .tony, dayMeal: dayMeal)

        subject.saveMealPlan()

        let subject2 = MealPlanningViewModel(modelContext: modelContext, startDate: date)
        subject2.loadMealPlan()

        let meal = subject2.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        #expect(meal?.recipe?.name == recipe.name)
    }

    // MARK: - Quick Meal Tests

    @Test("Set quick meal stores status")
    func setQuickMealStoresStatus() {
        let date = subject.weekDates[0]
        let mealType = MealType.lunch
        let dayMeal = DayMeal(mealType: mealType, date: date)

        subject.setQuickMeal(true, dayMeal: dayMeal)

        #expect(subject.isQuickMeal(forDayMeal: dayMeal))
    }

    @Test("Quick meal status defaults to false")
    func quickMealDefaultsToFalse() {
        let date = subject.weekDates[0]
        let mealType = MealType.dinner
        let dayMeal = DayMeal(mealType: mealType, date: date)

        let isQuick = subject.isQuickMeal(forDayMeal: dayMeal)

        #expect(!isQuick)
    }

    // MARK: - Edge Case Tests

    @Test("Swap meals with same day meal does nothing")
    func swapMealsWithSameDayMeal() {
        RecipeEntry.seedRecipes(into: modelContext)

        let recipes = modelContext.recipeResults()
        guard let recipe = recipes.first else {
            Issue.record("No recipes available")
            return
        }

        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.selectRecipe(recipe, for: .tony, dayMeal: dayMeal)

        subject.swapMeals(dayMeal, with: dayMeal)

        let meal = subject.mealSelections.first {
            $0.person == .tony && $0.dayMeal == dayMeal
        }
        #expect(meal?.recipe?.name == recipe.name)
    }

    @Test("Toggle meal selection twice returns to original state")
    func toggleMealSelectionTwiceReturnsToOriginal() {
        let date = subject.weekDates[0]
        let mealType = MealType.lunch
        let dayMeal = DayMeal(mealType: mealType, date: date)

        let originalState = subject.isSelected(for: .tony, dayMeal: dayMeal)

        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)
        subject.toggleMealSelection(for: .tony, dayMeal: dayMeal)

        let finalState = subject.isSelected(for: .tony, dayMeal: dayMeal)

        #expect(originalState == finalState)
    }

    @Test("Set empty reason removes reason from storage")
    func setEmptyReasonRemovesFromStorage() {
        let date = subject.weekDates[0]
        let dayMeal = DayMeal(mealType: .breakfast, date: date)

        subject.setReason("Initial reason", for: .tony, dayMeal: dayMeal)
        subject.setReason("", for: .tony, dayMeal: dayMeal)

        let reason = subject.getReason(for: .tony, dayMeal: dayMeal)

        #expect(reason.isEmpty)
    }

    @Test("Meals for day meal returns empty array for future date outside week")
    func mealsForDayMealOutsideWeek() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let mealType = MealType.dinner
        let dayMeal = DayMeal(mealType: mealType, date: futureDate)

        let meals = subject.meals(forDayMeal: dayMeal)

        #expect(meals.isEmpty)
    }

    // MARK: - Initialization Tests

    @Test("Initialize creates selections for all people and meal types")
    func initializeCreatesAllSelections() {
        let expectedCount = Person.allCases.count * 7 * MealType.allCases.count
        #expect(subject.mealSelections.count == expectedCount)
    }

    @Test("Initialize creates seven week dates")
    func initializeCreatesSevenDates() {
        #expect(subject.weekDates.count == 7)
    }

    @Test("Initialize sets all selections to selected by default")
    func initializeSetsAllSelectionsToSelected() {
        let allSelected = subject.mealSelections.allSatisfy { $0.isSelected }

        #expect(allSelected)
    }
}
