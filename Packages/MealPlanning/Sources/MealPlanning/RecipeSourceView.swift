//
//  RecipeSourceView.swift
//  Calories
//
//  Created by Tony Short on 26/12/2025.
//

import SwiftUI

struct RecipeSourceView: View {
    @Binding var currentPage: AddRecipePage
    @Binding var isPresented: Bool
    @Binding var extractedRecipeNames: [String]
    @Binding var dishPhoto: UIImage?
    @Binding var stepsPhoto: UIImage?

    @State private var showGenerateAlert = false
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 24) {
                    // Recipe Book Section
                    VStack(spacing: 16) {
                        Text("Recipe Book")
                            .font(.headline)
                            .foregroundColor(Colours.foregroundPrimary)

                        HStack(spacing: 12) {
                            RecipeThumbnail(label: "Dish photo", photo: $dishPhoto)
                            RecipeThumbnail(label: "Steps photo", photo: $stepsPhoto)
                        }
                        .frame(height: 200)

                        // Scan recipe button
                        Button(action: {
                            scanRecipe()
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
                        .disabled(stepsPhoto == nil || isScanning)
                        .opacity(stepsPhoto == nil ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)

                    // Divider with "or" label
                    HStack(spacing: 12) {
                        Divider()
                            .background(Colours.foregroundPrimary.opacity(0.3))
                        Text("or")
                            .font(.caption)
                            .foregroundColor(Colours.foregroundPrimary.opacity(0.6))
                        Divider()
                            .background(Colours.foregroundPrimary.opacity(0.3))
                    }
                    .padding(.horizontal)

                    // AI Generated Section
                    VStack(spacing: 16) {
                        Text("AI Generated")
                            .font(.headline)
                            .foregroundColor(Colours.foregroundPrimary)

                        Button(action: {
                            showGenerateAlert = true
                        }) {
                            Text("Generate Recipe")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Colours.backgroundSecondary)
                                .foregroundColor(Colours.foregroundPrimary)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Choose Recipe Source")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                }
                .foregroundColor(Colours.foregroundPrimary)
            }
        }
        .alert("Generate Recipe", isPresented: $showGenerateAlert) {
            Button("OK") {}
        } message: {
            Text("Will generate recipe")
        }
    }

    private func scanRecipe() {
        guard let photo = stepsPhoto else { return }

        Task {
            await MainActor.run {
                isScanning = true
            }

            let result = await RecipeTextExtractor.extractRecipeData(from: photo)

            if let result = result, !result.recipeNames.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)

                await MainActor.run {
                    extractedRecipeNames = result.recipeNames
                    isScanning = false
                    currentPage = .details
                }
            } else {
                await MainActor.run {
                    isScanning = false
                }
            }
        }
    }
}
