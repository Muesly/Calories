//
//  ContentView.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftUI
import CoreData

struct CaloriesView: View {
    @ObservedObject var viewModel: CaloriesViewModel
    @Environment(\.scenePhase) var scenePhase
    @State var totalCaloriesConsumed: Int = 0

    init(viewModel: CaloriesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                HeaderView(calorieStats: viewModel.calorieStats)
                AddEntryView(viewModel: viewModel, totalCaloriesConsumed: $totalCaloriesConsumed)
                List {
                    ForEach(viewModel.foodEntries) { foodEntry in
                        NavigationLink {
                            Text("Item at \(foodEntry.timeConsumed!, formatter: itemFormatter)")
                        } label: {
                            Text("\(foodEntry.timeConsumed ?? Date(), formatter: itemFormatter) / \(foodEntry.foodDescription) / \(foodEntry.calories)")
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .padding()
            .navigationTitle("Calories")
            Text("Select an item")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    try await viewModel.fetchStats()
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.deleteEntries(offsets: offsets)
        }
    }
}

struct HeaderView: View {
    @ObservedObject var calorieStats: CalorieStats

    init(calorieStats: CalorieStats) {
        self.calorieStats = calorieStats
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("BMR: \(calorieStats.bmr)")
                Text("Exercise: \(calorieStats.exercise)")
                Text("Combined: \(calorieStats.combinedExpenditure)")
            }
            VStack(alignment: .leading) {
                Text("Consumption: \(calorieStats.caloriesConsumed)")
                Text("Difference: \(calorieStats.difference)")
                Text("Deficit goal: \(calorieStats.deficitGoal)")
                Text("Can eat: \(calorieStats.canEat)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("mintGreen").opacity(0.3))
        .cornerRadius(10)
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
