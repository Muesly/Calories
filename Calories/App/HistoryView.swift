//
//  HistoryView.swift
//  Calories
//
//  Created by Tony Short on 10/02/2023.
//

import Foundation
import SwiftUI

struct HistoryView: View {
    private var viewModel: HistoryViewModel
    @Binding var entryChanged: Bool
    @State private var showingMealPicker = false
    @State private var selectedEntry: FoodEntry?
    @State private var newMealTime: Date = Date()

    init(
        viewModel: HistoryViewModel,
        entryChanged: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._entryChanged = entryChanged
    }

    var body: some View {
        ForEach(viewModel.daySections) { daySection in
            Section(header: Text(daySection.title)) {
                ForEach(daySection.meals) { meal in
                    DisclosureGroup(meal.summary) {
                        ForEach(meal.foodEntries) { foodEntry in
                            FoodEntryView(
                                foodEntry: foodEntry,
                                formatter: HistoryViewModel.timeConsumedTimeFormatter
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteItem(foodEntry)
                                } label: {
                                    Text("Delete")
                                }

                                Button {
                                    withAnimation {
                                        selectedEntry = foodEntry
                                        newMealTime = foodEntry.timeConsumed
                                        showingMealPicker = true
                                    }
                                } label: {
                                    Text("Move")
                                }
                                .tint(.blue)
                            }
                            .sheet(
                                isPresented: Binding(
                                    get: { showingMealPicker && (selectedEntry != nil) },
                                    set: { showingMealPicker = $0 }
                                )
                            ) {
                                VStack {
                                    Text(
                                        "Pick a meal to move \(selectedEntry?.foodDescription ?? "this item") to:"
                                    )
                                    MealPickerView(
                                        viewModel: MealPickerViewModel(timeConsumed: $newMealTime)
                                    )
                                    .padding()
                                    Button("Confirm") {
                                        if let selectedEntry {
                                            _ = withAnimation {
                                                Task {
                                                    moveItem(selectedEntry, to: newMealTime)
                                                    showingMealPicker = false
                                                }
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .presentationDetents([.medium])
                            }
                        }
                    }
                }
            }
        }
    }

    private func deleteItem(_ foodEntry: FoodEntry) {
        _ = withAnimation {
            Task {
                await viewModel.deleteFoodEntry(foodEntry)
                entryChanged = true
            }
        }
    }

    private func moveItem(_ foodEntry: FoodEntry, to newMealTime: Date) {
        _ = withAnimation {
            Task {
                await viewModel.moveFoodEntry(foodEntry, to: newMealTime)
                entryChanged = true
            }
        }
    }
}

struct FoodEntryView: View {
    let foodEntry: FoodEntry
    let formatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(foodEntry.timeConsumed, formatter: formatter)").opacity(0.5).font(.brand)
                Text("\(foodEntry.foodDescription)").font(.brand)
                Spacer()
                Text("\(Int(foodEntry.calories)) cals").opacity(0.5).font(.brand)
            }
            HStack {
                ForEach(foodEntry.plants ?? []) { plant in
                    if let image = plant.uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
        .listRowBackground(Colours.backgroundSecondary)
    }
}

#Preview {
    let plants: [PlantEntry] = [
        PlantEntry("Corn", imageName: "Corn"),
        PlantEntry("Rice", imageName: "Rice"),
        PlantEntry("Broccoli", imageName: "Broccoli"),
    ]
    FoodEntryView(
        foodEntry: .init(
            foodDescription: "Veggie Chilli",
            calories: 400,
            timeConsumed: Date(),
            plants: plants),
        formatter: HistoryViewModel.timeConsumedTimeFormatter
    )
    .padding()
}
