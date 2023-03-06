//
//  HistoryView.swift
//  Calories
//
//  Created by Tony Short on 10/02/2023.
//

import Foundation
import SwiftUI

struct HistoryView: View {
    @ObservedObject var calorieStats: CalorieStats
    private let viewModel: CaloriesViewModel

    init(viewModel: CaloriesViewModel,
         calorieStats: CalorieStats) {
        self.viewModel = viewModel
        self.calorieStats = calorieStats
    }

    var body: some View {
        ForEach(viewModel.daySections) { daySection in
            Section(header: Text("\(daySection.title)")) {
                ForEach(daySection.foodEntries) { foodEntry in
                    HStack {
                        Text("\(foodEntry.timeConsumed!, formatter: viewModel.timeConsumedTimeFormatter)").opacity(0.5).font(.brand)
                        Text("\(foodEntry.foodDescription)").font(.brand)
                        Spacer()
                        Text("\(Int(foodEntry.calories)) cals").opacity(0.5).font(.brand)
                    }
                    .listRowBackground(Colours.backgroundSecondary)
                }
            }
        }
        .onDelete(perform: deleteItems)
    }

    private func deleteItems(offsets: IndexSet) {
        _ = withAnimation {
            Task {
                await viewModel.deleteEntries(offsets: offsets)
                await calorieStats.fetchCaloriesConsumed()
            }
        }
    }
}
