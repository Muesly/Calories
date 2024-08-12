//
//  AddExerciseView.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import Foundation
import SwiftUI

struct AddExerciseView: View {
    private let viewModel: AddExerciseViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State var searchText = ""
    @State private var exerciseDescription: String = ""
    @State private var calories: Int = 0
    @State private var timeExercised: Date = Date()
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @Binding var showingAddExerciseView: Bool
    
    init(viewModel: AddExerciseViewModel,
         showingAddExerciseView: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingAddExerciseView = showingAddExerciseView
    }
    
    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    NavigationLink {
                        Text("Screen to add details on new exercise")
                    } label: {
                        Text("Add \(searchText) as a new exercise").bold()
                    }
                }
                Section("Recent exercises") {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        Text(suggestion.name)
                            .listRowBackground(Colours.backgroundSecondary)
                    }
                }
            }
            .searchable(text: $searchText,
                        placement:  .navigationBarDrawer(displayMode: .always),
                        prompt: "Enter exercise")
            .accessibilityIdentifier("Exercise List")

            Spacer()
                .navigationTitle("Add new exercise")
                .toolbar {
                    ToolbarItem {
                        Button("Close") {
                            self.showingAddExerciseView = false
                        }
                    }
                }
                .onAppear {
                    viewModel.fetchSuggestions(searchText: searchText)
                }
                .onChange(of: searchText) { _, searchText in
                    viewModel.fetchSuggestions(searchText: searchText)
                }
        }
        .font(.brand)
    }
}
