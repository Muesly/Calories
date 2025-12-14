//
//  MealPickerView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftUI

struct MealPickerView: View {
    @ObservedObject var viewModel: MealPlanningViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.weekDates, id: \.self) { date in
                    DayMealSelectionView(date: date) { mealType, date in
                        let meal = viewModel.meal(forDay: date, mealType: mealType)
                        RecipePickerCard(
                            mealType: mealType,
                            meal: meal,
                            onTap: {
                                // TODO: Show recipe picker
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            viewModel.fetchRecipes()
        }
    }
}

struct RecipePickerCard: View {
    let mealType: MealType
    let meal: MealSelection
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(mealType.rawValue) \(mealType.iconName)")
                .font(.subheadline)
                .foregroundColor(Colours.foregroundPrimary)
            Divider()
                .background(Colours.foregroundPrimary)

            Text(meal.recipe?.name ?? "Select recipe...")
                .font(.caption)
                .foregroundColor(Colours.foregroundPrimary)
                .lineLimit(3)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colours.backgroundSecondary.opacity(0.5))
        .cornerRadius(8)
        .onTapGesture { onTap() }
    }
}
