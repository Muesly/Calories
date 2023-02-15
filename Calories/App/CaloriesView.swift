//
//  ContentView.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftUI
import CoreData

struct CaloriesView: View {
    private let viewModel = CaloriesViewModel()
    @StateObject var calorieStats: CalorieStats
    @Environment(\.scenePhase) var scenePhase
    @State var showingAddEntryView = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 40) {
                        WeeklyChartView(viewModel: .init())
                        Button {
                            showingAddEntryView = true
                        } label: {
                            Text("Add food or drink").font(.brand)
                                .padding(10)
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                HistoryView(viewModel: viewModel, calorieStats: calorieStats)
            }
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .navigationTitle("Today's Calories")
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    calorieStats.fetchStats()
                }
            }
            .sheet(isPresented: $showingAddEntryView) {
                AddEntryView(viewModel: AddEntryViewModel(calorieStats: calorieStats),
                             showingAddEntryView: $showingAddEntryView)
            }
            .background(Colours.backgroundPrimary)
        }

    }
}

