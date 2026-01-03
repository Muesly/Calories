//
//  CreateRecipeSheet.swift
//  Calories
//
//  Created by Tony Short on 23/12/2025.
//

import SwiftData
import SwiftUI

struct CreateRecipeSheet: View {
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    let mealType: MealType
    let onRecipeCreated: (RecipeEntry) -> Void
    @State var currentPage: AddRecipePage
    @State var extractedRecipeNames: [String]
    @State var dishPhoto: UIImage?
    @State var stepsPhoto: UIImage? = nil
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
        .task {
            if AppFlags.showRecipeShortcut {
                extractedRecipeNames = ["Breakfast Muffin", "Next option"]
                dishPhoto = UIImage(named: "ExampleDish")
                stepsPhoto = UIImage(named: "ExampleSteps")
                currentPage = .details
            }
        }
    }
}

enum AddRecipePage {
    case source
    case details
}
