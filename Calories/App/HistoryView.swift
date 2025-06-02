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
    @Binding var entryDeleted: Bool

    init(
        viewModel: HistoryViewModel,
        entryDeleted: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._entryDeleted = entryDeleted
    }

    var body: some View {
        ForEach(viewModel.daySections) { daySection in
            Section(header: Text(daySection.title)) {
                ForEach(daySection.meals) { meal in
                    DisclosureGroup(meal.summary) {
                        ForEach(meal.foodEntries) { foodEntry in
                            FoodEntryView(
                                foodEntry: foodEntry,
                                formatter: HistoryViewModel.timeConsumedTimeFormatter)
                        }
                        .onDelete { indexSet in
                            self.deleteItem(atRow: indexSet.first, inFoodEntries: meal.foodEntries)
                        }
                    }
                }
            }
        }
    }

    private func deleteItem(atRow row: Int?, inFoodEntries foodEntries: [FoodEntry]) {
        _ = withAnimation {
            Task {
                await viewModel.deleteEntries(atRow: row, inFoodEntries: foodEntries)
                entryDeleted = true
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
