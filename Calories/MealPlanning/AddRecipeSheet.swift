//
//  AddRecipeSheet.swift
//  Calories
//
//  Created by Tony Short on 23/12/2025.
//

import SwiftData
import SwiftUI

struct AddRecipeSheet: View {
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    let mealType: MealType
    let onRecipeCreated: (RecipeEntry) -> Void
    @State private var currentPage: AddRecipePage = .source
    @State private var extractedRecipeNames: [String] = []
    @State private var dishPhoto: UIImage? = nil
    @State private var stepsPhoto: UIImage? = nil
    @State private var showCancelAlert = false

    var body: some View {
        NavigationStack {
            switch currentPage {
            case .source:
                RecipeSourceView(
                    currentPage: $currentPage,
                    isPresented: $isPresented,
                    extractedRecipeNames: $extractedRecipeNames,
                    dishPhoto: $dishPhoto,
                    stepsPhoto: $stepsPhoto
                )
            case .details:
                RecipeDetailsView(
                    currentPage: $currentPage,
                    isPresented: $isPresented,
                    modelContext: modelContext,
                    mealType: mealType,
                    extractedRecipeNames: extractedRecipeNames,
                    onRecipeCreated: onRecipeCreated,
                    dishPhoto: $dishPhoto,
                    stepsPhoto: $stepsPhoto,
                )
            }
        }
    }
}

enum AddRecipePage {
    case source
    case details
}
