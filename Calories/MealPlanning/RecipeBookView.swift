//
//  RecipeBookView.swift
//  Calories
//
//  Created by Tony Short on 23/12/2025.
//

import SwiftUI

struct RecipeBookView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
            }
            .padding(20)
            .navigationTitle("Pick a recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Colours.foregroundPrimary)
                }
            }
        }
    }
}

#Preview {
    RecipeBookView()
}
