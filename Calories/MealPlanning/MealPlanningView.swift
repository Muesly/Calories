//
//  MealPlanningView.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import SwiftUI

struct MealPlanningView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Empty screen for now
                Spacer()
                Text("Meal Planning")
                    .font(.brand)
                    .foregroundColor(Colours.foregroundPrimary)
                Spacer()
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