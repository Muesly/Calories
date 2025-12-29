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
    @State var searchText = ""
    @State private var isSearching: Bool = false

    var suitableRecipes: [RecipeEntry] {
        allRecipes.filter { recipe in
            let suitability = recipe.suitability(for: mealType)
            guard suitability != .never else {
                return false
            }
            if searchText.count < 2 {
                return true
            } else {
                return recipe.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(suitableRecipes, id: \.name) { recipe in
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
                    .onDelete(perform: deleteRecipes)
                }
            }
            .navigationTitle("Recipe book")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                isPresented: $isSearching,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Enter Recipe"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(Colours.foregroundPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(Colours.foregroundPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddRecipe) {
            AddRecipeSheet(isPresented: $showAddRecipe, modelContext: modelContext)
        }
    }

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            let recipe = suitableRecipes[index]
            modelContext.delete(recipe)
        }
        try? modelContext.save()
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
