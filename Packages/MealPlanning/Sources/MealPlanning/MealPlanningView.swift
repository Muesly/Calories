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
    @State private var showFoodToUseUp = false

    init(viewModel: MealPlanningViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                MealPickerView(viewModel: viewModel)
            }

            Button(action: {
                showFoodToUseUp = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Populate")
                }
                .modifier(ButtonText())
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
        }
        .font(.brand)
        .onAppear {
            RecipeEntry.seedRecipes(into: modelContext)
            viewModel.loadMealPlan()
        }
        .sheet(isPresented: $showFoodToUseUp) {
            NavigationStack {
                FoodToUseUpView(viewModel: viewModel)
                    .navigationTitle("Foods to Use Up")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showFoodToUseUp = false
                                viewModel.populateMealRecipes()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    MealPlanningView(
        viewModel: MealPlanningViewModel(
            modelContext: modelContext,
            startDate: Date().startOfPlanningWeek))
}
