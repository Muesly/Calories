//
//  MealPlanningView.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import Foundation
import SwiftData
import SwiftUI

struct MealPlanningView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @State var viewModel: MealPlanningViewModel

    init(viewModel: MealPlanningViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let stage = viewModel.currentStage
        NavigationStack {
            VStack {
                switch stage {
                case .mealAvailability:
                    MealAvailabilityView(viewModel: viewModel)
                case .foodToUseUp:
                    FoodToUseUpView(viewModel: viewModel)
                case .mealPicking:
                    MealPickerView(
                        modelContext: modelContext, viewModel: viewModel, onSave: saveMealPlan)
                }
            }

            HStack(spacing: 15) {
                if viewModel.canGoBack {
                    Button(action: {
                        viewModel.goToPreviousStage()
                    }) {
                        Text("Back")
                            .modifier(ButtonText())
                    }
                    .buttonStyle(.bordered)
                }

                if stage == .mealPicking {
                    Button(action: {
                        viewModel.populateEmptyMeals()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Populate")
                        }
                        .modifier(ButtonText())
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button(action: {
                        viewModel.goToNextStage()
                    }) {
                        Text("Next")
                            .modifier(ButtonText())
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canGoForward)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Meal Planning")
        .toolbar {
            if stage == .mealPicking {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMealPlan()
                        dismiss()
                    }
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .font(.brand)
        .onAppear {
            RecipeEntry.seedRecipes(into: modelContext)
            viewModel.loadMealPlan()
        }
    }

    private func saveMealPlan() {
        viewModel.saveMealPlan()
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    MealPlanningView(viewModel: MealPlanningViewModel(modelContext: modelContext))
}
