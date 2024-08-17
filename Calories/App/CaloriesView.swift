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
    @Environment(\.healthStore) var healthStore

    private let historyViewModel: HistoryViewModel
    private let weeklyChartViewModel: WeeklyChartViewModel

    @State var showingAddEntryView = false
    @State var showingAddExerciseView = false
    @State var showingRecordWeightView = false
    @State var entryDeleted = false

    init(historyViewModel: HistoryViewModel,
         weeklyChartViewModel: WeeklyChartViewModel) {
        self.historyViewModel = historyViewModel
        self.weeklyChartViewModel = weeklyChartViewModel
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
            .navigationTitle("Today's Calories")
            .background(Colours.backgroundPrimary)
            .font(.brand)
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .sheet(isPresented: $showingAddEntryView) {
                AddFoodView(viewModel: AddFoodViewModel(healthStore: healthStore),
                             showingAddEntryView: $showingAddEntryView)
            }
            .sheet(isPresented: $showingAddExerciseView) {
                AddExerciseView(viewModel: AddExerciseViewModel(healthStore: healthStore),
                                showingAddExerciseView: $showingAddExerciseView)
            }
            .sheet(isPresented: $showingRecordWeightView) {
                RecordWeightView(viewModel: RecordWeightViewModel(healthStore: healthStore))
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refresh()
                }
            }
            .onChange(of: entryDeleted) { _, isDeleted in
                if isDeleted == true {
                    refresh()
                }
                entryDeleted = false
            }
            .onChange(of: showingAddEntryView) { _, isBeingShown in
                if !isBeingShown { refresh() }
            }
            .onChange(of: showingAddExerciseView) { _, isBeingShown in
                if !isBeingShown { refresh() }
            }
        }
    }

    private func refresh() {
        historyViewModel.fetchDaySections()
        Task {
            await weeklyChartViewModel.fetchDaysCalorieData()
            try? await scheduleTomorrowsMotivationalMessage()
        }
    }

    private func scheduleTomorrowsMotivationalMessage() async throws {

        let notificationCenter = UNUserNotificationCenter.current()
        guard await notificationCenter.pendingNotificationRequests().count == 0 else {
            return
        }

        let content = UNMutableNotificationContent()

        let companion = Companion(messageDetails: Companion.defaultMessages)

        let weeklyWeightChange = try await healthStore.weeklyWeightChange()
        let monthlyWeightChange = try await healthStore.monthlyWeightChange()
        let tomorrow = Date().addingTimeInterval(86400)
        var dateComponents = Calendar.current.dateComponents([.weekday], from: tomorrow)

        let (message, scheduledHour) = try companion.nextMotivationalMessage(weekday: dateComponents.weekday!,
                                                                         weeklyWeightChange: weeklyWeightChange,
                                                                         monthlyWeightChange: monthlyWeightChange)
        dateComponents.hour = scheduledHour

        content.body = message
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)
        try await notificationCenter.add(request)
    }
}
