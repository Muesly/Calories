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
    private let viewModel: MealPlanningViewModel

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
                    MealPickerView(viewModel: viewModel)
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

                Button(action: {
                    viewModel.goToNextStage()
                }) {
                    Text("Next")
                        .modifier(ButtonText())
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canGoForward)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Meal Planning")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .font(.brand)
        .onAppear {
            RecipeEntry.seedRecipes(into: modelContext)
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    MealPlanningView(viewModel: MealPlanningViewModel(modelContext: modelContext))
}
