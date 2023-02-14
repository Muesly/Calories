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
        List {
            ForEach(viewModel.foodEntries) { foodEntry in
                HStack {
                    Text("\(foodEntry.timeConsumed!, formatter: itemFormatter)")
                    Text("\(foodEntry.foodDescription)")
                    Text("\(Int(foodEntry.calories)) calories")
                }
            }
            .onDelete(perform: deleteItems)
        }
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
