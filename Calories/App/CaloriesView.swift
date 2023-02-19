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
    @Environment(\.scenePhase) var scenePhase
    @State var showingAddEntryView = false
    @State var showingAddExerciseView = false
    private let weeklyChartViewModel = WeeklyChartViewModel()
    @State var entryDeleted = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 40) {
                        WeeklyChartView(viewModel: weeklyChartViewModel)
                        HStack {
                            Button {
                                showingAddExerciseView = true
                            } label: {
                                Text("Add exercise").font(.brand)
                                    .padding(10)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            Button {
                                showingAddEntryView = true
                            } label: {
                                Text("Add food").font(.brand)
                                    .padding(10)
                                    .bold()
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                HistoryView(viewModel: viewModel, entryDeleted: $entryDeleted)
            }
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .navigationTitle("Today's Calories")
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    refresh()
                }
            }
            .onChange(of: entryDeleted) { isDeleted in
                if isDeleted == true {
                    refresh()
                }
                entryDeleted = false
            }
            .onChange(of: showingAddEntryView) { isBeingShown in
                if !isBeingShown {
                    refresh()
                }
            }
            .onChange(of: showingAddExerciseView) { isBeingShown in
                if !isBeingShown {
                    refresh()
                }
            }
            .sheet(isPresented: $showingAddEntryView) {
                AddEntryView(viewModel: AddEntryViewModel(),
                             showingAddEntryView: $showingAddEntryView)
            }
            .sheet(isPresented: $showingAddExerciseView) {
                AddExerciseView(viewModel: AddExerciseViewModel(),
                                showingAddExerciseView: $showingAddExerciseView)
            }
            .background(Colours.backgroundPrimary)
        }

    }

    private func refresh() {
        Task {
            await weeklyChartViewModel.fetchDaysCalorieData()
            await viewModel.fetchDaySections()
        }
    }
}

