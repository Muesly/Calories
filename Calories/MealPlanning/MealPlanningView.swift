//
//  MealPlanningView.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import Foundation
import SwiftUI

enum WizardStage {
    case mealSelection
    case freezerMeals
    case existingItems
    case mealPicking
}

struct MealPlanningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MealPlanningViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.currentStage {
                case .mealSelection:
                    EmptyView()
                case .freezerMeals:
                    EmptyView()
                case .existingItems:
                    EmptyView()
                case .mealPicking:
                    EmptyView()
                }
            }
            .background(Colours.backgroundPrimary)
            .navigationTitle("Meal Planning")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .font(.brand)
    }
}

#Preview {
    MealPlanningView()
}
