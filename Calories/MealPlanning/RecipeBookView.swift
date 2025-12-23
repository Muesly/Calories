//
//  RecipeBookView.swift
//  Calories
//
//  Created by Tony Short on 23/12/2025.
//

import SwiftData
import SwiftUI

struct RecipeBookView: View {
    let mealType: MealType
    let onRecipeSelected: (RecipeEntry) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var allRecipes: [RecipeEntry]
    @State private var showAddRecipe = false

    var suitableRecipes: [RecipeEntry] {
        allRecipes.filter { recipe in
            let suitability = recipe.suitability(for: mealType)
            return suitability != .never
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List(suitableRecipes, id: \.name) { recipe in
                    Button(action: {
                        onRecipeSelected(recipe)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.body)
                                .foregroundColor(Colours.foregroundPrimary)
                            Text(suitabilityLabel(for: recipe))
                                .font(.caption)
                                .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddRecipe = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(Colours.foregroundPrimary)
                                .padding(20)
                                .background(Colours.backgroundSecondary)
                                .clipShape(Circle())
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Recipe book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Colours.foregroundPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddRecipe) {
            AddRecipeSheet(isPresented: $showAddRecipe, modelContext: modelContext)
        }
    }

    private func suitabilityLabel(for recipe: RecipeEntry) -> String {
        let suitability = recipe.suitability(for: mealType)
        switch suitability {
        case .always:
            return "Great for this meal"
        case .some:
            return "Good for this meal"
        case .never:
            return "Not suitable"
        }
    }
}

// MARK: - Private Extensions

extension RecipeEntry {
    fileprivate func suitability(for mealType: MealType) -> MealSuitability {
        switch mealType {
        case .breakfast: breakfastSuitability
        case .lunch: lunchSuitability
        case .dinner: dinnerSuitability
        default: .never
        }
    }
}

#Preview {
    RecipeBookView(mealType: .breakfast, onRecipeSelected: { _ in })
        .modelContainer(for: RecipeEntry.self, inMemory: true)
}
