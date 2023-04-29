//
//  ContentView.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftUI
import CoreData

struct CaloriesView: View {
    @Environment(\.scenePhase) var scenePhase

    private let historyViewModel = HistoryViewModel()
    private let weeklyChartViewModel = WeeklyChartViewModel()

    @State var showingAddEntryView = false
    @State var showingAddExerciseView = false
    @State var showingRecordWeightView = false
    @State var entryDeleted = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 30) {
                        WeeklyChartView(viewModel: weeklyChartViewModel)
                        VStack(spacing: 10) {
                            HStack {
                                Button { showingAddExerciseView = true } label: { Text("Add exercise").modifier(ButtonText()) }
                                    .buttonStyle(.borderedProminent)
                                Button { showingAddEntryView = true } label: { Text("Add food").modifier(ButtonText()) }
                                    .buttonStyle(.borderedProminent)
                            }
                            Button { showingRecordWeightView = true } label: { Text("Record weight").modifier(ButtonText()) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
                HistoryView(viewModel: historyViewModel, entryDeleted: $entryDeleted)
            }
            .navigationTitle("Today's Calories")
            .background(Colours.backgroundPrimary)
            .font(.brand)
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .sheet(isPresented: $showingAddEntryView) {
                AddEntryView(viewModel: AddEntryViewModel(),
                             showingAddEntryView: $showingAddEntryView)
            }
            .sheet(isPresented: $showingAddExerciseView) {
                AddExerciseView(viewModel: AddExerciseViewModel(),
                                showingAddExerciseView: $showingAddExerciseView)
            }
            .sheet(isPresented: $showingRecordWeightView) {
                RecordWeightView(viewModel: RecordWeightViewModel())
            }
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
                if !isBeingShown { refresh() }
            }
            .onChange(of: showingAddExerciseView) { isBeingShown in
                if !isBeingShown { refresh() }
            }
        }
    }

    private func refresh() {
        Task {
            await weeklyChartViewModel.fetchDaysCalorieData()
            await historyViewModel.fetchDaySections()
        }
    }
}
