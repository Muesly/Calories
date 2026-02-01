//
//  MealChoiceView.swift
//  Calories
//
//  Created by Claude Code on 23/12/2025.
//

import SwiftUI
import CaloriesFoundation

struct MealChoiceView: View {
    let recipe: RecipeEntry
    let mealType: MealType
    let servingInfo: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(servingInfo)
                        .font(.caption)
                        .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                }
                .padding(.vertical, 8)

                Spacer()
            }
            .padding(20)
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Colours.foregroundPrimary)
                }
            }
        }
    }
}

#Preview {
    MealChoiceView(
        recipe: RecipeEntry(
            name: "Scrambled Eggs on Toast",
            breakfastSuitability: .always,
            lunchSuitability: .sometimes,
            dinnerSuitability: .sometimes
        ),
        mealType: .breakfast,
        servingInfo: "2 x servings"
    )
}
