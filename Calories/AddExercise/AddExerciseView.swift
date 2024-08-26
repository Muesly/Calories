//
//  AddExerciseView.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import Foundation
import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismissSearch) private var dismissSearch

    private let viewModel: AddExerciseViewModel
    @State var searchText = ""
    @State var addedExerciseEntry: ExerciseEntry?
    @State private var timeExercised: Date

    @State private var showingAddExerciseDetailsView: Bool = false
    @Binding var showingAddExerciseView: Bool
    @State private var isSearching: Bool = false

    init(viewModel: AddExerciseViewModel,
         showingAddExerciseView: Binding<Bool>,
         timeExercised: Date = Date()) {
        self.viewModel = viewModel
        self._showingAddExerciseView = showingAddExerciseView
        self.timeExercised = timeExercised
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !searchText.isEmpty {
                        Button {
                            showingAddExerciseDetailsView = true
                        } label: {
                            Text("Add \(searchText) as a new exercise").bold()
                        }
                    }
                    Section("Recent exercises") {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                searchText = suggestion.name
                                showingAddExerciseDetailsView = true
                            } label: {
                                Text(suggestion.name)
                            }
                            .listRowBackground(Colours.backgroundSecondary)
                        }
                    }
                }
                .navigationDestination(isPresented: $showingAddExerciseDetailsView) {
                    addExerciseInputFieldsView(description: searchText)
                }
            }
            .foregroundColor(.white)
            .font(.brand)
            .searchable(text: $searchText,
                        isPresented: $isSearching,
                        placement:  .navigationBarDrawer(displayMode: .always),
                        prompt: "Enter exercise")
            .onSubmit(of: .search) {
                dismissSearch()
                showingAddExerciseDetailsView = true
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
            .onChange(of: showingAddExerciseDetailsView) { _, isPresented in
                if !isPresented {
                    searchText = ""
                    dismissSearch()
                    isSearching = false
                }
            }
            .onChange(of: addedExerciseEntry) { _, addedExerciseEntry in
                if let addedExerciseEntry {
                    timeExercised = addedExerciseEntry.timeExercised
                }
                viewModel.fetchSuggestions(searchText: searchText)
            }
        }
    }

    private func addExerciseInputFieldsView(description: String) -> AddExerciseDetailsView {
        AddExerciseDetailsView(viewModel: viewModel,
                               exerciseTemplate: viewModel.exerciseTemplateFor(description),
                               addedExerciseEntry: $addedExerciseEntry,
                               isExerciseDetailsViewPresented: $showingAddExerciseDetailsView)
    }
}

