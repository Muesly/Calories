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
            VStack {
                HeaderView(calorieStats: calorieStats)
                Button {
                    showingAddEntryView = true
                } label: {
                    Text("Add")
                        .foregroundColor(.black)
                        .padding(10)
                }
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundColor(Color("mintGreen"))
                HistoryView(viewModel: viewModel, calorieStats: calorieStats)
            }
            .padding()
            .navigationTitle("Calories")
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    calorieStats.fetchStats()
                }
            }
            .sheet(isPresented: $showingAddEntryView) {
                AddEntryView(viewModel: AddEntryViewModel(calorieStats: calorieStats),
                             showingAddEntryView: $showingAddEntryView)
            }
        }
    }
}

