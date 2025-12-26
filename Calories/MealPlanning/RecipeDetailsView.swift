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
    let extractedRecipeNames: [String]
    let stepsPhoto: UIImage?

    @State private var recipeName = ""
    @State private var breakfastSuitability: MealSuitability = .never
    @State private var lunchSuitability: MealSuitability = .never
    @State private var dinnerSuitability: MealSuitability = .never
    @State private var showCameraSheet = false
    @State private var fullScreenPhoto: UIImage? = nil
    @State private var showFullScreenPhoto = false
    @State private var photoZoomScale: CGFloat = 1.0
    @State private var photoOffset: CGSize = .zero
    @State private var showScanError = false
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

                SuitabilitySection(title: "Breakfast", selection: $breakfastSuitability)
                SuitabilitySection(title: "Lunch", selection: $lunchSuitability)
                SuitabilitySection(title: "Dinner", selection: $dinnerSuitability)
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
                .disabled(!isFormValid)
            }
        }
        .fullScreenCover(isPresented: $showFullScreenPhoto) {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            photoZoomScale = 1.0
                            photoOffset = .zero
                            showFullScreenPhoto = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }

                    Spacer()

                    if let photo = fullScreenPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(photoZoomScale)
                            .offset(photoOffset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            photoZoomScale = max(1.0, value)
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            photoOffset = value.translation
                                        }
                                )
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if photoZoomScale > 1.5 {
                                        photoZoomScale = 1.0
                                        photoOffset = .zero
                                    } else {
                                        photoZoomScale = 2.5
                                    }
                                }
                            }
                            .padding()
                    }

                    Spacer()
                }
            }
            .onChange(of: showFullScreenPhoto) { oldValue, newValue in
                if !newValue {
                    photoZoomScale = 1.0
                    photoOffset = .zero
                }
            }
        }
        .alert("No Recipe Photo", isPresented: $showScanError) {
            Button("OK") {}
        } message: {
            Text("Please take a photo of the recipe steps first before scanning.")
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
        }
    }

    private func saveRecipe() {
        do {
            let newRecipe = RecipeEntry(
                name: recipeName,
                breakfastSuitability: breakfastSuitability,
                lunchSuitability: lunchSuitability,
                dinnerSuitability: dinnerSuitability
            )
            modelContext.insert(newRecipe)
            try modelContext.save()
            isPresented = false
        } catch {
            saveErrorMessage = error.localizedDescription
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

    var body: some View {
        Section(header: Text(title)) {
            Picker("\(title) Suitability", selection: $selection) {
                Text("Never").tag(MealSuitability.never)
                Text("Sometimes").tag(MealSuitability.some)
                Text("Always").tag(MealSuitability.always)
            }
            .pickerStyle(.segmented)
        }
    }
}
