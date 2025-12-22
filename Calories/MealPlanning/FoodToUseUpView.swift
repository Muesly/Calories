//
//  FoodToUseUpView.swift
//  Calories
//
//  Created by Tony Short on 07/12/2025.
//

import SwiftUI

struct FoodToUseUpView: View {
    @State var viewModel: MealPlanningViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.foodToUseUp) { item in
                    FoodItemCard(item: item, viewModel: viewModel)
                }

                AddItemButton(action: { viewModel.addFoodItem() })
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct FoodItemCard: View {
    let item: FoodToUseUp
    @ObservedObject var viewModel: MealPlanningViewModel
    @State private var name: String = ""
    @State private var isFullMeal: Bool = false
    @State private var isFrozen: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Item name...", text: $name)
                    .font(.body)
                    .foregroundColor(Colours.foregroundPrimary)

                Button(action: { removeItem() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Colours.foregroundPrimary.opacity(0.5))
                }
            }

            HStack(spacing: 20) {
                Toggle(isOn: $isFullMeal) {
                    Text("Full meal")
                        .font(.caption)
                        .foregroundColor(Colours.foregroundPrimary)
                }
                .toggleStyle(CheckboxToggleStyle())

                Toggle(isOn: $isFrozen) {
                    Text("Frozen")
                        .font(.caption)
                        .foregroundColor(Colours.foregroundPrimary)
                }
                .toggleStyle(CheckboxToggleStyle())

                Spacer()

                Text(isFullMeal ? "🍲" : "🥩")
                    .font(.title2)
            }
        }
        .padding(12)
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
        .onAppear { loadState() }
        .onChange(of: name) { _, _ in saveState() }
        .onChange(of: isFullMeal) { _, _ in saveState() }
        .onChange(of: isFrozen) { _, _ in saveState() }
    }

    private func loadState() {
        name = item.name
        isFullMeal = item.isFullMeal
        isFrozen = item.isFrozen
    }

    private func saveState() {
        var updated = item
        updated.name = name
        updated.isFullMeal = isFullMeal
        updated.isFrozen = isFrozen
        viewModel.updateFoodItem(updated)
    }

    private func removeItem() {
        viewModel.removeFoodItem(withId: item.id)
    }
}

struct AddItemButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add item")
            }
            .font(.body)
            .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
