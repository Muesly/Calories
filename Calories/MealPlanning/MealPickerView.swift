//
//  MealPickerView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftData
import SwiftUI

struct MealPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: MealPlanningViewModel
    @State private var swapMode = false
    @State private var dayMealToSwap: DayMeal?
    @Environment(\.dismiss) var dismiss
    @State var showCreateRecipe = false
    @State var mealForCreatedRecipe: MealSelection?

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.weekDates, id: \.self) { date in
                            DayMealSelectionView(date: date) { dayMeal in
                                let meals = viewModel.meals(forDayMeal: dayMeal)
                                RecipePickerCard(
                                    dayMeal: dayMeal,
                                    meals: meals,
                                    servingInfo: viewModel.servingInfo(forDayMeal: dayMeal),
                                    isSwapMode: swapMode,
                                    isSelectedForSwap: dayMealToSwap == dayMeal,
                                    onRecipeSelected: { recipe in
                                        if let meal = meals.first {
                                            let person = meal.person
                                            viewModel.selectRecipe(
                                                recipe, for: person, dayMeal: dayMeal)
                                            swapMode = false
                                        }
                                    },
                                    onCreateRecipe: {
                                        showCreateRecipe = true
                                        if let meal = meals.first {
                                            mealForCreatedRecipe = meal
                                        }
                                    },
                                    onSwapRequested: {
                                        if swapMode && dayMealToSwap != nil {
                                            viewModel.swapMeals(dayMealToSwap!, with: dayMeal)
                                            swapMode = false
                                            dayMealToSwap = nil
                                        } else {
                                            swapMode = true
                                            dayMealToSwap = dayMeal
                                        }
                                    },
                                    onRemoveMeal: {
                                        if let meal = meals.first {
                                            let person = meal.person
                                            viewModel.clearMeal(for: person, dayMeal: dayMeal)
                                        }
                                    },
                                    personSelections: personSelections(dayMeal: dayMeal),
                                    personReasons: personReasons(dayMeal: dayMeal),
                                    isQuickMeal: viewModel.isQuickMeal(forDayMeal: dayMeal),
                                    isPinned: viewModel.isPinnedMeal(forDayMeal: dayMeal),
                                    onTogglePerson: { person in
                                        viewModel.toggleMealSelection(
                                            for: person, dayMeal: dayMeal)
                                    },
                                    onReasonChanged: { person, reason in
                                        viewModel.setReason(
                                            reason, for: person, dayMeal: dayMeal)
                                    },
                                    onQuickMealToggled: { isQuick in
                                        viewModel.setQuickMeal(
                                            isQuick, dayMeal: dayMeal)
                                    },
                                    onPinnedToggled: { isPinned in
                                        viewModel.setPinnedMeal(
                                            isPinned, dayMeal: dayMeal)
                                    }
                                )
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.goToPreviousWeek() }) {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.goToNextWeek() }) {
                        Image(systemName: "chevron.right")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if swapMode {
                        Button("Cancel Swap") {
                            swapMode = false
                            dayMealToSwap = nil
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateRecipe) {
                if let meal = mealForCreatedRecipe {
                    CreateRecipeSheet(
                        isPresented: $showCreateRecipe,
                        mealType: meal.dayMeal.mealType,
                        onRecipeCreated: { recipe in
                            viewModel.selectRecipe(
                                recipe, for: meal.person, dayMeal: meal.dayMeal)
                            swapMode = false
                            showCreateRecipe = false
                        },
                        currentPage: AppFlags.showRecipeShortcut ? .details : .source,
                        extractedRecipeNames: AppFlags.showRecipeShortcut
                            ? ["Breakfast Muffin", "Next option"] : [],
                        dishPhoto: AppFlags.showRecipeShortcut ? UIImage(named: "Corn") : nil
                    )
                }
            }
            .task {
                if AppFlags.showRecipeShortcut {
                    showCreateRecipe = true
                    mealForCreatedRecipe = viewModel.meals(
                        forDayMeal: .init(mealType: .breakfast, date: viewModel.weekDates.first!)
                    ).first!
                }
            }
        }
    }

    private func personSelections(dayMeal: DayMeal) -> [Person: Bool] {
        var selections: [Person: Bool] = [:]
        for person in Person.allCases {
            selections[person] = viewModel.isSelected(for: person, dayMeal: dayMeal)
        }
        return selections
    }

    private func personReasons(dayMeal: DayMeal) -> [Person: String] {
        var reasons: [Person: String] = [:]
        for person in Person.allCases {
            reasons[person] = viewModel.getReason(for: person, dayMeal: dayMeal)
        }
        return reasons
    }
}
