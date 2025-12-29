//
//  RecipeDetailsDisplayView.swift
//  Calories
//
//  Created by Claude Code on 29/12/2025.
//

import SwiftUI

struct RecipeDetailsDisplayView: View {
    let recipe: RecipeEntry
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Form {
                    Section(header: Text("Recipe Name")) {
                        Text(recipe.name)
                            .font(.body)
                            .foregroundColor(Colours.foregroundPrimary)
                    }

                    if recipe.caloriesPerPortion > 0 {
                        Section(header: Text("Calories per Portion")) {
                            Text("\(recipe.caloriesPerPortion)")
                                .font(.body)
                                .foregroundColor(Colours.foregroundPrimary)
                        }
                    }

                    if let book = recipe.book {
                        Section(header: Text("Recipe Book")) {
                            Text(book.name)
                                .font(.body)
                                .foregroundColor(Colours.foregroundPrimary)
                        }
                    }

                    Section(header: Text("Images")) {
                        HStack(spacing: 12) {
                            RecipeThumbnail(
                                label: "Dish photo",
                                photo: Binding(
                                    get: {
                                        UIImage(data: recipe.dishPhotoData ?? Data())
                                    }, set: { _ in }))
                            RecipeThumbnail(
                                label: "Steps photo",
                                photo: Binding(
                                    get: {
                                        UIImage(data: recipe.stepsPhotoData ?? Data())
                                    }, set: { _ in }))
                        }
                        .frame(height: 200)
                    }

                    if !recipe.suggestions.isEmpty {
                        Section(header: Text("Suggestions")) {
                            Text(recipe.suggestions)
                                .font(.body)
                                .foregroundColor(Colours.foregroundPrimary)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Recipe Details")
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
    RecipeDetailsDisplayView(
        recipe: RecipeEntry(
            name: "Scrambled Eggs on Toast",
            breakfastSuitability: .always,
            lunchSuitability: .sometimes,
            dinnerSuitability: .sometimes
        )
    )
}
