//
//  HistoryView.swift
//  Calories
//
//  Created by Tony Short on 10/02/2023.
//

import Foundation
import SwiftUI

struct HistoryView: View {
    @ObservedObject private var viewModel: CaloriesViewModel
    @Binding var entryDeleted: Bool

    init(viewModel: CaloriesViewModel,
         entryDeleted: Binding<Bool>) {
        self.viewModel = viewModel
        self._entryDeleted = entryDeleted
    }

    var body: some View {
        ForEach(viewModel.daySections) { daySection in
            Section(header: Text("\(daySection.title)")) {
                ForEach(daySection.foodEntries) { foodEntry in
                    HStack {
                        Text("\(foodEntry.timeConsumed ?? Date(), formatter: viewModel.timeConsumedTimeFormatter)").opacity(0.5).font(.brand)
                        Text("\(foodEntry.foodDescription)").font(.brand)
                        Spacer()
                        Text("\(Int(foodEntry.calories)) cals").opacity(0.5).font(.brand)
                    }
                    .listRowBackground(Colours.backgroundSecondary)
                }
                .onDelete { indexSet in
                    self.deleteItem(atRow: indexSet.first, inFoodEntries: daySection.foodEntries)
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
