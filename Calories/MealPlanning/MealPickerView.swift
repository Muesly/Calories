//
//  MealPickerView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftUI

struct MealPickerView: View {
    @State var viewModel: MealPlanningViewModel

    var body: some View {
        NavigationStack {
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
                                    onRecipeSelected: { recipe in
                                        let person = meal.person
                                        let mealDate = date
                                        let mealType = mealType
                                        viewModel.selectRecipe(
                                            recipe, for: person, date: mealDate, mealType: mealType)
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
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Populate") {
                        $viewModel.wrappedValue.populateEmptyMeals()
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
    let onRecipeSelected: (RecipeEntry) -> Void

    @State private var showMealChoice = false

    private var isNoMealRequired: Bool {
        servingInfo.hasPrefix("No meal required")
    }

    var body: some View {
        Button(action: {
            guard !isNoMealRequired else {
                return
            }
            showMealChoice = true
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
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .background(Colours.foregroundPrimary)

                    Text(servingInfo)
                        .font(.caption2)
                        .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colours.backgroundSecondary.opacity(0.5))
        .cornerRadius(8)
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
    }
}
