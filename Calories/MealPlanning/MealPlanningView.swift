//
//  MealPlanningView.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import Foundation
import SwiftUI

struct MealPlanningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MealPlanningViewModel()

    var body: some View {
        let stage = viewModel.currentStage
        NavigationStack {
            VStack {
                switch stage {
                case .mealAvailability:
                    MealAvailabilityView(viewModel: viewModel)
                case .freezerMeals:
                    EmptyView()
                case .existingItems:
                    EmptyView()
                case .mealPicking:
                    EmptyView()
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
    }
}

#Preview {
    MealPlanningView()
}
