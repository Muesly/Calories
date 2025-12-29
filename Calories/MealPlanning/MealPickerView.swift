//
//  MealPickerView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftUI

struct MealPickerView: View {
    @State var viewModel: MealPlanningViewModel
    let onSave: () -> Void
    @State private var swapMode = false
    @State private var mealToSwap: MealSelection?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.weekDates, id: \.self) { date in
                            DayMealSelectionView(date: date) { mealType, date in
                                if let meal = viewModel.meal(forDate: date, mealType: mealType) {
                                    RecipePickerCard(
                                        mealType: mealType,
                                        meal: meal,
                                        servingInfo: viewModel.servingInfo(
                                            for: date, mealType: mealType),
                                        isSwapMode: swapMode,
                                        isSelectedForSwap: mealToSwap?.id == meal.id,
                                        onRecipeSelected: { recipe in
                                            let person = meal.person
                                            viewModel.selectRecipe(
                                                recipe, for: person, date: date, mealType: mealType)
                                            swapMode = false
                                        },
                                        onChangeRequested: {
                                            // Change will be handled internally in RecipePickerCard
                                        },
                                        onSwapRequested: {
                                            if swapMode && mealToSwap != nil {
                                                viewModel.swapMeals(mealToSwap!, with: meal)
                                                swapMode = false
                                                mealToSwap = nil
                                            } else {
                                                swapMode = true
                                                mealToSwap = meal
                                            }
                                        }
                                    )
                                }
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveMealPlan()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if swapMode {
                        Button("Cancel Swap") {
                            swapMode = false
                            mealToSwap = nil
                        }
                    }
                }
            }
        }
    }
}

struct RecipePickerCard: View {
    let mealType: MealType
    let meal: MealSelection
    let servingInfo: String
    let isSwapMode: Bool
    let isSelectedForSwap: Bool
    let onRecipeSelected: (RecipeEntry) -> Void
    let onChangeRequested: (() -> Void)?
    let onSwapRequested: (() -> Void)?

    @State private var showMealChoice = false
    @State private var showRecipeBook = false

    private var isNoMealRequired: Bool {
        servingInfo.hasPrefix("No meal required")
    }

    var body: some View {
        Button(action: {
            // In swap mode, clicking the card triggers swap
            if isSwapMode {
                onSwapRequested?()
            } else if !isNoMealRequired {
                showMealChoice = true
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(mealType.rawValue) \(mealType.iconName)")
                    .font(.subheadline)
                    .foregroundColor(Colours.foregroundPrimary)
                Divider()
                    .background(Colours.foregroundPrimary)

                if isNoMealRequired {
                    Text(servingInfo)
                        .font(.caption)
                        .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                        .italic()
                } else {
                    Text(meal.recipe?.name ?? "Choose a meal")
                        .font(.caption)
                        .foregroundColor(Colours.foregroundPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .background(Colours.foregroundPrimary)

                    HStack {
                        Text(servingInfo)
                            .font(.caption2)
                            .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                        Spacer()
                        if !isSwapMode {
                            Menu {
                                Button(action: {
                                    showRecipeBook = true
                                }) {
                                    Label("Change", systemImage: "pencil")
                                }
                                if let onSwapRequested = onSwapRequested {
                                    Button(action: onSwapRequested) {
                                        Label("Swap", systemImage: "arrow.left.arrow.right")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                                    .padding(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelectedForSwap
                ? Colours.backgroundSecondary
                : (isSwapMode
                    ? Colours.backgroundSecondary.opacity(0.5)
                    : Colours.backgroundSecondary.opacity(0.5))
        )
        .cornerRadius(8)
        .overlay(
            isSelectedForSwap
                ? RoundedRectangle(cornerRadius: 8)
                    .stroke(Colours.foregroundPrimary, lineWidth: 2)
                : nil
        )
        .sheet(isPresented: $showMealChoice) {
            if let recipe = meal.recipe {
                MealChoiceView(
                    recipe: recipe,
                    mealType: mealType,
                    servingInfo: servingInfo
                )
            } else {
                RecipeBookView(
                    mealType: mealType,
                    onRecipeSelected: onRecipeSelected
                )
            }
        }
        .sheet(isPresented: $showRecipeBook) {
            RecipeBookView(
                mealType: mealType,
                onRecipeSelected: onRecipeSelected
            )
        }
    }
}
