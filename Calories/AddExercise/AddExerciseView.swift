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
    @Environment(\.dismissSearch) private var dismissSearch
    @State var searchText = ""
    @State private var readyToNavigateToAddExerciseInputFields: Bool = false
    @State var exerciseAdded = false
    @State private var timeExercised: Date = Date()
    @Binding var showingAddExerciseView: Bool
    
    init(viewModel: AddExerciseViewModel,
         showingAddExerciseView: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingAddExerciseView = showingAddExerciseView
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    NavigationLink {
                        addExerciseInputFieldsView(description: searchText)
                    } label: {
                        Text("Add \(searchText) as a new exercise").bold()
                    }
                }
                Section("Recent exercises") {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        NavigationLink {
                            addExerciseInputFieldsView(description: suggestion.name)
                        } label: {
                            Text(suggestion.name)
                        }
                        .listRowBackground(Colours.backgroundSecondary)
                    }
                }
            }
            .font(.brand)
            .searchable(text: $searchText,
                        placement:  .navigationBarDrawer(displayMode: .always),
                        prompt: "Enter exercise")
            .onSubmit(of: .search) {
                dismissSearch()
                readyToNavigateToAddExerciseInputFields = true
            }
            .accessibilityIdentifier("Exercise List")
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
            .onChange(of: exerciseAdded) { _, exerciseAdded in
                if exerciseAdded {
                    self.showingAddExerciseView = false
                }
            }
            .navigationDestination(isPresented: $readyToNavigateToAddExerciseInputFields) {
                addExerciseInputFieldsView(description: searchText)
            }
        }
    }

    private func addExerciseInputFieldsView(description: String) -> AddExerciseDetailsView {
        AddExerciseDetailsView(viewModel: viewModel,
                                   defExerciseDescription: description,
                                   defCalories: 0,
                                   defTimeConsumed: $timeExercised,
                                   searchText: $searchText,
                                   exerciseAdded: $exerciseAdded)
    }
}

