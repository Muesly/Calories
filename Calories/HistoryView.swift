//
//  HistoryView.swift
//  Calories
//
//  Created by Tony Short on 10/02/2023.
//

import Foundation
import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: CaloriesViewModel

    init(viewModel: CaloriesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.foodEntries) { foodEntry in
                NavigationLink {
                    Text("Item at \(foodEntry.timeConsumed!, formatter: itemFormatter)")
                } label: {
                    HStack {
                        Text("\(foodEntry.timeConsumed!, formatter: itemFormatter)")
                        Text("\(foodEntry.foodDescription)")
                        Text("\(Int(foodEntry.calories)) calories")
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.deleteEntries(offsets: offsets)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
