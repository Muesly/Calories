//
//  AddPlantView.swift
//  Calories
//
//  Created by Tony Short on 19/08/2024.
//

import SwiftUI

struct AddPlantView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    @Environment(\.dismiss) var dismiss
    @State var viewModel: AddPlantViewModel
    @State var searchText = ""
    @Binding var addedPlant: String
    @State private var isSearching: Bool = true

    init(viewModel: AddPlantViewModel,
         addedPlant: Binding<String>) {
        self.viewModel = viewModel
        self._addedPlant = addedPlant
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !searchText.isEmpty {
                        Button {
                            addedPlant = searchText
                            dismiss()
                        } label: {
                            Text("Add \(searchText) as a new plant").bold()
                        }
                    }
                    Section("Common plants") {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                addedPlant = suggestion.name
                                dismiss()
                            } label: {
                                Text(suggestion.name)
                            }
                            .listRowBackground(Colours.backgroundSecondary)
                        }
                    }
                }
                .foregroundColor(.white)
                .accessibilityIdentifier("Plant List")
                .navigationTitle("Add Plant")
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .font(.brand)
        .onAppear {
            viewModel.fetchSuggestions(searchText: searchText)
        }
        .onChange(of: searchText) { _, searchText in
            viewModel.fetchSuggestions(searchText: searchText)
        }
        .searchable(text: $searchText,
                    isPresented: $isSearching,
                    placement:  .navigationBarDrawer(displayMode: .always),
                    prompt: "Enter Plant")
        .onSubmit(of: .search) {
            addedPlant = searchText
            dismiss()
        }
    }
}
