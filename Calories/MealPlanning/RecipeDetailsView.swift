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
    @State private var isScanning = false
    @State private var extractedRecipeNameCandidates: [String] = []
    @State private var extractedIngredientCandidates: [RecipeIngredientCandidate] = []
    @State private var recipeIngredients: [RecipeIngredientCandidate] = []
    @State private var stepsPhoto: UIImage? = nil

    var isFormValid: Bool {
        let hasName = !recipeName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAtLeastOneSuitability =
            breakfastSuitability != .never || lunchSuitability != .never
            || dinnerSuitability != .never
        return hasName && hasAtLeastOneSuitability
    }

    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                if stepsPhoto != nil {
                    scanRecipe(from: stepsPhoto!)
                } else {
                    showScanError = true
                }
            }) {
                if isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Colours.foregroundPrimary)
                        Text("Scanning...")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Colours.backgroundSecondary)
                    .foregroundColor(Colours.foregroundPrimary)
                    .cornerRadius(8)
                } else {
                    Text("Scan recipe")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Colours.backgroundSecondary)
                        .foregroundColor(Colours.foregroundPrimary)
                        .cornerRadius(8)
                }
            }
            .disabled(isScanning)
            .padding(.horizontal)

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

                if !recipeIngredients.isEmpty {
                    Section(header: Text("Ingredients")) {
                        ForEach(recipeIngredients, id: \.id) { ingredient in
                            Text(ingredient.ingredientName)
                                .font(.body)
                                .foregroundColor(Colours.foregroundPrimary)
                        }
                        .onDelete(perform: deleteIngredients)
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
                    var recipeIngredientsForSave: [RecipeIngredient] = []
                    for ingredient in recipeIngredients {
                        let ingredientEntry =
                            modelContext.findIngredient(
                                ingredient.ingredientName, isPlant: false)
                            ?? IngredientEntry(ingredient.ingredientName, isPlant: false)
                        let recipeIngredient = RecipeIngredient(
                            ingredient: ingredientEntry
                        )
                        recipeIngredientsForSave.append(recipeIngredient)
                        modelContext.insert(ingredientEntry)
                        modelContext.insert(recipeIngredient)
                    }

                    let newRecipe = RecipeEntry(
                        name: recipeName,
                        breakfastSuitability: breakfastSuitability,
                        lunchSuitability: lunchSuitability,
                        dinnerSuitability: dinnerSuitability,
                        recipeIngredients: recipeIngredientsForSave
                    )
                    modelContext.insert(newRecipe)
                    try? modelContext.save()
                    isPresented = false
                }
                .foregroundColor(Colours.foregroundPrimary)
                .disabled(!isFormValid)
            }
        }
        .sheet(isPresented: $showCameraSheet) {
            CameraViewControllerRepresentable { image in
                scanRecipe(from: image)
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
    }

    private func scanRecipe(from image: UIImage) {
        Task {
            await MainActor.run {
                isScanning = true
            }

            let (recipeNames, ingredients) = await RecipeTextExtractor.extractRecipeData(
                from: image)

            if !recipeNames.isEmpty || !ingredients.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)

                await MainActor.run {
                    extractedRecipeNameCandidates = recipeNames
                    extractedIngredientCandidates = ingredients
                    recipeIngredients = ingredients
                    if !recipeNames.isEmpty {
                        recipeName = recipeNames[0]
                    }
                    isScanning = false
                }
            } else {
                await MainActor.run {
                    isScanning = false
                }
            }
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
