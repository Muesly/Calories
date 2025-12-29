//
//  RecipeDetailsView.swift
//  Calories
//
//  Created by Tony Short on 26/12/2025.
//

import SwiftData
import SwiftUI

struct RecipeDetailsView: View {
    @Binding var currentPage: AddRecipePage
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    let mealType: MealType
    let extractedRecipeNames: [String]
    let onRecipeCreated: (RecipeEntry) -> Void
    @Binding var dishPhoto: UIImage?
    @Binding var stepsPhoto: UIImage?

    @State private var recipeName = ""
    @State private var breakfastSuitability: MealSuitability = .never
    @State private var lunchSuitability: MealSuitability = .never
    @State private var dinnerSuitability: MealSuitability = .never
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var recipeIngredients: [RecipeIngredientCandidate] = []

    private var extractedRecipeNameCandidates: [String] {
        extractedRecipeNames
    }

    var isFormValid: Bool {
        let hasName = !recipeName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAtLeastOneSuitability =
            breakfastSuitability != .never || lunchSuitability != .never
            || dinnerSuitability != .never
        return hasName && hasAtLeastOneSuitability
    }

    var body: some View {
        VStack(spacing: 16) {

            Form {
                Section(header: Text("Recipe Name")) {
                    VStack(spacing: 12) {
                        HStack {
                            TextField("Enter recipe name", text: $recipeName)
                            if !extractedRecipeNameCandidates.isEmpty {
                                Menu {
                                    ForEach(extractedRecipeNameCandidates, id: \.self) {
                                        candidate in
                                        Button(action: {
                                            recipeName = candidate
                                        }) {
                                            Text(candidate)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Colours.foregroundPrimary)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Images")) {
                    HStack(spacing: 12) {
                        RecipeThumbnail(label: "Dish photo", photo: $dishPhoto)
                        RecipeThumbnail(label: "Steps photo", photo: $stepsPhoto)
                    }
                    .frame(height: 200)
                }

                Section(header: Text("Meal Suitability")) {
                    VStack(spacing: 12) {
                        SuitabilitySection(title: "Breakfast", selection: $breakfastSuitability)
                        SuitabilitySection(title: "Lunch", selection: $lunchSuitability)
                        SuitabilitySection(title: "Dinner", selection: $dinnerSuitability)
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Add Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(Colours.foregroundPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveRecipe()
                }
                .foregroundColor(Colours.foregroundPrimary)
            }
        }
        .alert("Failed to Save Recipe", isPresented: $showSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
        .onAppear {
            if !extractedRecipeNames.isEmpty {
                recipeName = extractedRecipeNames[0]
            }

            // Set default suitability based on meal type
            switch mealType {
            case .breakfast:
                breakfastSuitability = .always
            case .lunch:
                lunchSuitability = .always
            case .dinner:
                dinnerSuitability = .always
            default:
                break
            }
        }
    }

    private func saveRecipe() {
        guard isFormValid else {
            saveErrorMessage = "Please ensure all required fields are entered"
            showSaveError = true
            return
        }

        do {
            let newRecipe = RecipeEntry(
                name: recipeName,
                breakfastSuitability: breakfastSuitability,
                lunchSuitability: lunchSuitability,
                dinnerSuitability: dinnerSuitability
            )
            modelContext.insert(newRecipe)
            try modelContext.save()
            print("✓ Recipe saved successfully: \(recipeName)")
            isPresented = false
            onRecipeCreated(newRecipe)
        } catch {
            print("✗ Error saving recipe: \(error)")
            if error.localizedDescription.contains("UNIQUE constraint failed")
                || error.localizedDescription.contains("duplicate")
            {
                saveErrorMessage = "A recipe with the name '\(recipeName)' already exists"
            } else {
                saveErrorMessage = "Failed to save recipe: \(error.localizedDescription)"
            }
            showSaveError = true
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        recipeIngredients.remove(atOffsets: offsets)
    }
}

// MARK: - Recipe Ingredient Candidate

struct RecipeIngredientCandidate: Identifiable {
    let id = UUID()
    let ingredientName: String
}

// MARK: - Suitability Section

struct SuitabilitySection: View {
    let title: String
    @Binding var selection: MealSuitability
    private let mealLabelWidth = 80.0

    var body: some View {
        HStack {
            Text(title)
                .frame(width: mealLabelWidth, alignment: .trailing)
            Picker("", selection: $selection) {
                Text("Never").tag(MealSuitability.never)
                Text("Sometimes").tag(MealSuitability.sometimes)
                Text("Always").tag(MealSuitability.always)
            }.pickerStyle(.segmented)
        }
    }
}
