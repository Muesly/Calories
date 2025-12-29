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

    init() {
        let modelContext = ModelContext(.inMemory)
        subject = MealPlanningViewModel(modelContext: modelContext)
    }

    // MARK: - Attendee Count Tests

    @Test("Attendee count when both present")
    func attendeeCountWhenBothPresent() {
        let date = Date()
        let mealType = MealType.breakfast

        let count = subject.attendeeCount(for: date, mealType: mealType)

        #expect(count == 2)
    }

    @Test("Attendee count when one absent")
    func attendeeCountWhenOneAbsent() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)

        let count = subject.attendeeCount(for: date, mealType: mealType)

        #expect(count == 1)
    }

    @Test("Attendee count when both absent")
    func attendeeCountWhenBothAbsent() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.toggleMealSelection(for: .karen, date: date, mealType: mealType)

        let count = subject.attendeeCount(for: date, mealType: mealType)

        #expect(count == 0)
    }

    // MARK: - Serving Info Tests

    @Test("Serving info when both present")
    func servingInfoWhenBothPresent() {
        let date = Date()
        let mealType = MealType.breakfast

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "2 x servings")
    }

    @Test("Serving info when one absent with reason")
    func servingInfoWhenOneAbsentWithReason() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.setReason("Working late", for: .tony, date: date, mealType: mealType)

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "1 x serving (Tony - Working late)")
    }

    @Test("Serving info when one absent without reason")
    func servingInfoWhenOneAbsentWithoutReason() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "1 x serving (Tony)")
    }

    @Test("Serving info when both absent with same reason")
    func servingInfoWhenBothAbsentSameReason() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.toggleMealSelection(for: .karen, date: date, mealType: mealType)
        subject.setReason("Out of town", for: .tony, date: date, mealType: mealType)
        subject.setReason("Out of town", for: .karen, date: date, mealType: mealType)

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "No meal required - Out of town")
    }

    @Test("Serving info when both absent with different reasons")
    func servingInfoWhenBothAbsentDifferentReasons() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.toggleMealSelection(for: .karen, date: date, mealType: mealType)
        subject.setReason("Working late", for: .tony, date: date, mealType: mealType)
        subject.setReason("Doctor appointment", for: .karen, date: date, mealType: mealType)

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "No meal required - Tony: Working late, Karen: Doctor appointment")
    }

    @Test("Serving info when both absent with no reasons")
    func servingInfoWhenBothAbsentNoReasons() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.toggleMealSelection(for: .karen, date: date, mealType: mealType)

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "No meal required")
    }

    @Test("Serving info when both absent with one reason")
    func servingInfoWhenBothAbsentOneWithReason() {
        var subject = self.subject
        let date = Date()
        let mealType = MealType.breakfast

        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.toggleMealSelection(for: .karen, date: date, mealType: mealType)
        subject.setReason("Traveling", for: .tony, date: date, mealType: mealType)

        let info = subject.servingInfo(for: date, mealType: mealType)

        #expect(info == "No meal required - Traveling")
    }

    // MARK: - fetchRecipes Tests

    @Test("Fetch recipes picks recipe when at least one person present")
    func fetchRecipesPicksRecipeWhenAtLeastOnePersonPresent() {
        let modelContext = ModelContext(.inMemory)
        RecipeEntry.seedRecipes(into: modelContext)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        subject.fetchRecipes()

        let date = subject.weekDates[0]
        let mealType = MealType.breakfast
        let meal = subject.meal(forDate: date, mealType: mealType)

        #expect(meal?.recipe != nil)
    }

    @Test("Fetch recipes does not pick recipe when both absent")
    func fetchRecipesDoesNotPickRecipeWhenBothAbsent() {
        let modelContext = ModelContext(.inMemory)
        RecipeEntry.seedRecipes(into: modelContext)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        let date = subject.weekDates[0]
        let mealType = MealType.breakfast
        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)
        subject.toggleMealSelection(for: .karen, date: date, mealType: mealType)

        subject.fetchRecipes()

        let mealTony = subject.mealSelections.first {
            $0.person == .tony && $0.date.isSameDay(as: date) && $0.mealType == mealType
        }
        let mealKaren = subject.mealSelections.first {
            $0.person == .karen && $0.date.isSameDay(as: date) && $0.mealType == mealType
        }

        #expect(mealTony?.recipe == nil)
        #expect(mealKaren?.recipe == nil)
    }

    @Test("Fetch recipes picks same recipe for both people")
    func fetchRecipesPicksSameRecipeForBothPeople() {
        let modelContext = ModelContext(.inMemory)
        RecipeEntry.seedRecipes(into: modelContext)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        subject.fetchRecipes()

        let date = subject.weekDates[0]
        let mealType = MealType.breakfast
        let mealTony = subject.mealSelections.first {
            $0.person == .tony && $0.date.isSameDay(as: date) && $0.mealType == mealType
        }
        let mealKaren = subject.mealSelections.first {
            $0.person == .karen && $0.date.isSameDay(as: date) && $0.mealType == mealType
        }

        #expect(mealTony?.recipe?.name == mealKaren?.recipe?.name)
    }

    // MARK: - startOfPlanningWeek Tests

    @Test("Start of planning week Monday to Wednesday")
    func startOfPlanningWeekMondayToWednesday() {
        let monday = dateForWeekday(2)
        let tuesday = dateForWeekday(3)
        let wednesday = dateForWeekday(4)

        let mondayResult = MealPlanningViewModel.startOfPlanningWeek(from: monday)
        let tuesdayResult = MealPlanningViewModel.startOfPlanningWeek(from: tuesday)
        let wednesdayResult = MealPlanningViewModel.startOfPlanningWeek(from: wednesday)

        #expect(Calendar.current.component(.weekday, from: mondayResult) == 2)
        #expect(Calendar.current.component(.weekday, from: tuesdayResult) == 2)
        #expect(Calendar.current.component(.weekday, from: wednesdayResult) == 2)

        #expect(mondayResult.isSameDay(as: tuesdayResult))
        #expect(tuesdayResult.isSameDay(as: wednesdayResult))
    }

    @Test("Start of planning week Thursday to Sunday")
    func startOfPlanningWeekThursdayToSunday() {
        let thursday = dateForWeekday(5)
        let friday = dateForWeekday(6)
        let saturday = dateForWeekday(7)
        let sunday = dateForWeekday(1)

        let thursdayResult = MealPlanningViewModel.startOfPlanningWeek(from: thursday)
        let fridayResult = MealPlanningViewModel.startOfPlanningWeek(from: friday)
        let saturdayResult = MealPlanningViewModel.startOfPlanningWeek(from: saturday)
        let sundayResult = MealPlanningViewModel.startOfPlanningWeek(from: sunday)

        #expect(Calendar.current.component(.weekday, from: thursdayResult) == 2)
        #expect(Calendar.current.component(.weekday, from: fridayResult) == 2)
        #expect(Calendar.current.component(.weekday, from: saturdayResult) == 2)
        #expect(Calendar.current.component(.weekday, from: sundayResult) == 2)

        #expect(thursdayResult.isSameDay(as: fridayResult))
        #expect(fridayResult.isSameDay(as: saturdayResult))
        #expect(saturdayResult.isSameDay(as: sundayResult))

        let calendar = Calendar.current
        let daysDifference =
            calendar.dateComponents([.day], from: thursday, to: thursdayResult).day ?? 0
        #expect(daysDifference > 0)
    }

    // MARK: - Swap Meals Tests

    @Test("Swap meals exchanges recipes")
    func swapMealsExchangesRecipes() {
        let modelContext = ModelContext(.inMemory)
        RecipeEntry.seedRecipes(into: modelContext)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        let recipes = modelContext.recipeResults()
        guard recipes.count >= 2 else {
            Issue.record("Not enough recipes for swap test")
            return
        }

        let date = subject.weekDates[0]
        let mealType1 = MealType.breakfast
        let mealType2 = MealType.lunch

        let meal1 = subject.mealSelections.first {
            $0.person == .tony && $0.date.isSameDay(as: date) && $0.mealType == mealType1
        }!
        let meal2 = subject.mealSelections.first {
            $0.person == .tony && $0.date.isSameDay(as: date) && $0.mealType == mealType2
        }!

        subject.selectRecipe(recipes[0], for: .tony, date: date, mealType: mealType1)
        subject.selectRecipe(recipes[1], for: .tony, date: date, mealType: mealType2)

        subject.swapMeals(meal1, with: meal2)

        let swappedMeal1 = subject.mealSelections.first {
            $0.person == .tony && $0.date.isSameDay(as: date) && $0.mealType == mealType1
        }!
        let swappedMeal2 = subject.mealSelections.first {
            $0.person == .tony && $0.date.isSameDay(as: date) && $0.mealType == mealType2
        }!

        #expect(swappedMeal1.recipe?.name == recipes[1].name)
        #expect(swappedMeal2.recipe?.name == recipes[0].name)
    }

    // MARK: - Food To Use Up Tests

    @Test("Add food item appends to list")
    func addFoodItemAppends() {
        var subject = self.subject
        let initialCount = subject.foodToUseUp.count

        subject.addFoodItem()

        #expect(subject.foodToUseUp.count == initialCount + 1)
    }

    @Test("Remove food item by index")
    func removeFoodItemByIndex() {
        var subject = self.subject
        subject.addFoodItem()
        subject.addFoodItem()
        let countBefore = subject.foodToUseUp.count

        subject.removeFoodItem(at: 0)

        #expect(subject.foodToUseUp.count == countBefore - 1)
    }

    @Test("Remove food item by id")
    func removeFoodItemById() {
        var subject = self.subject
        subject.addFoodItem()
        let item = subject.foodToUseUp[0]

        subject.removeFoodItem(withId: item.id)

        #expect(subject.foodToUseUp.isEmpty)
    }

    @Test("Update food item")
    func updateFoodItem() {
        var subject = self.subject
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
        let modelContext = ModelContext(.inMemory)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        let date = subject.weekDates[0]
        let mealType = MealType.breakfast
        subject.toggleMealSelection(for: .tony, date: date, mealType: mealType)

        subject.saveMealPlan()

        // Create new view model to load data
        var subject2 = MealPlanningViewModel(modelContext: modelContext)
        subject2.loadMealPlan()

        let isSelected = subject2.isSelected(for: .tony, date: date, mealType: mealType)
        #expect(!isSelected)
    }

    @Test("Load and save meal plan preserves reasons")
    func loadAndSaveMealPlanPreservesReasons() {
        let modelContext = ModelContext(.inMemory)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        let date = subject.weekDates[0]
        let mealType = MealType.breakfast
        subject.setReason("Working late", for: .tony, date: date, mealType: mealType)

        subject.saveMealPlan()

        // Create new view model to load data
        var subject2 = MealPlanningViewModel(modelContext: modelContext)
        subject2.loadMealPlan()

        let reason = subject2.getReason(for: .tony, date: date, mealType: mealType)
        #expect(reason == "Working late")
    }

    @Test("Load and save meal plan preserves quick meals")
    func loadAndSaveMealPlanPreservesQuickMeals() {
        let modelContext = ModelContext(.inMemory)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        let date = subject.weekDates[0]
        let mealType = MealType.breakfast
        subject.setQuickMeal(true, for: date, mealType: mealType)

        subject.saveMealPlan()

        // Create new view model to load data
        var subject2 = MealPlanningViewModel(modelContext: modelContext)
        subject2.loadMealPlan()

        let isQuick = subject2.isQuickMeal(for: date, mealType: mealType)
        #expect(isQuick)
    }

    @Test("Load and save meal plan preserves food to use up")
    func loadAndSaveMealPlanPreservesFoodToUseUp() {
        let modelContext = ModelContext(.inMemory)
        var subject = MealPlanningViewModel(modelContext: modelContext)

        subject.addFoodItem()
        var item = subject.foodToUseUp[0]
        item.name = "Leftover pasta"

        subject.updateFoodItem(item)
        subject.saveMealPlan()

        // Create new view model to load data
        var subject2 = MealPlanningViewModel(modelContext: modelContext)
        subject2.loadMealPlan()

        #expect(subject2.foodToUseUp.count == 1)
        #expect(subject2.foodToUseUp[0].name == "Leftover pasta")
    }

    // MARK: - Helper Methods

    private func dateForWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let daysToAdd = (weekday - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd, to: now) ?? now
    }
}
