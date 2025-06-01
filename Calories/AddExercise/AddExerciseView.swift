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
    @State var timeExerciseAdded: Date?

    @State private var showingAddExerciseDetailsView: Bool = false
    @Binding var showingAddExerciseView: Bool
    @State private var isSearching: Bool = false

    init(viewModel: AddExerciseViewModel,
         showingAddExerciseView: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingAddExerciseView = showingAddExerciseView
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
                        ForEach(viewModel.suggestions, id: \.name) { suggestion in
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
                    AddExerciseDetailsView(viewModel: viewModel,
                                           exerciseTemplate: viewModel.exerciseTemplateFor(searchText),
                                           timeExerciseAdded: $timeExerciseAdded,
                                           isExerciseDetailsViewPresented: $showingAddExerciseDetailsView)
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
            .onChange(of: timeExerciseAdded) { _, _ in
                viewModel.fetchSuggestions(searchText: searchText)
            }
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddExerciseView(viewModel: AddExerciseViewModel(healthStore: MockHealthStore(),
                                                    modelContext: modelContext,
                                                    timeExercised: Date()),
                    showingAddExerciseView: .constant(false))
}
