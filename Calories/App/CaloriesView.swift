//
//  ContentView.swift
//  Calories
//
//  Created by Tony Short on 06/02/2023.
//

import SwiftData
import SwiftUI

struct CaloriesView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext

    private let historyViewModel: HistoryViewModel
    private let weeklyChartViewModel: WeeklyChartViewModel
    private let healthStore: HealthStore
    private let companion: Companion

    @State var showingAddEntryView = false
    @State var showingAddExerciseView = false
    @State var showingRecordWeightView = false
    @State var entryDeleted = false

    @State private var currentDate: Date
    private let overriddenCurrentDate: Date?

    init(healthStore: HealthStore,
         companion: Companion,
         overriddenCurrentDate: Date? = nil) {
        self.overriddenCurrentDate = overriddenCurrentDate
        let currentDate = overriddenCurrentDate ?? Date()
        self.weeklyChartViewModel = WeeklyChartViewModel(healthStore: healthStore, currentDate: currentDate)
        self.healthStore = healthStore
        self.companion = companion
        self.currentDate = currentDate
        self.historyViewModel = HistoryViewModel(healthStore: healthStore)
    }

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
            .navigationTitle("Calories")
            .background(Colours.backgroundPrimary)
            .font(.brand)
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .sheet(isPresented: $showingAddEntryView) {
                AddFoodView(viewModel: AddFoodViewModel(healthStore: healthStore,
                                                        modelContext: modelContext),
                             showingAddEntryView: $showingAddEntryView)
                    .environment(\.currentDate, currentDate)
            }
            .sheet(isPresented: $showingAddExerciseView) {
                AddExerciseView(viewModel: AddExerciseViewModel(healthStore: healthStore,
                                                                modelContext: modelContext,
                                                                timeExercised: currentDate),
                                showingAddExerciseView: $showingAddExerciseView)
                    .environment(\.currentDate, currentDate)
            }
            .sheet(isPresented: $showingRecordWeightView) {
                RecordWeightView(viewModel: RecordWeightViewModel(healthStore: healthStore))
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refresh()
                    currentDate = overriddenCurrentDate ?? Date()
                }
            }
            .onChange(of: entryDeleted) { _, isDeleted in
                if isDeleted == true {
                    refresh()
                }
                entryDeleted = false
            }
            .onChange(of: showingAddEntryView) { _, isBeingShown in
                if !isBeingShown {
                    refresh()
                }
            }
            .onChange(of: showingAddExerciseView) { _, isBeingShown in
                if !isBeingShown { refresh() }
            }
            .onAppear {
                historyViewModel.modelContext = modelContext
                weeklyChartViewModel.modelContext = modelContext
                companion.requestNotificationsPermission()
                refresh()

            }
        }
    }

    private func refresh() {
        Task {
            historyViewModel.fetchDaySections(forDate: currentDate)
            await weeklyChartViewModel.fetchData(currentDate: currentDate)
            await scheduleTomorrowsMotivationalMessage()
        }
    }

    private func scheduleTomorrowsMotivationalMessage() async {
        do {
            let weeklyWeightChange = try await healthStore.weeklyWeightChange()
            let monthlyWeightChange = try await healthStore.monthlyWeightChange()
            let context = MotivationalContext(date: Date(),
                                              weeklyWeightChange: weeklyWeightChange,
                                              monthlyWeightChange: monthlyWeightChange)
            try? await companion.scheduleTomorrowsMotivationalMessage(context: context)
        } catch {
            fatalError("Failed to fetch weight changes: \(error)")
        }
    }
}

#Preview {
    let healthStore = HealthStoreFactory.createNull()
    CaloriesView(healthStore: healthStore,
                 companion: Companion.createNull())
}
