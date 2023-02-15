//
//  AddEntryView.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import SwiftUI

struct AddEntryView: View {
    private var viewModel: AddEntryViewModel
    @State private var searchText = ""
    @State private var readyToNavigateToAddEntryInputFields : Bool = false
    @Binding var showingAddEntryView: Bool
    @State private var newEntryAdded: Bool = false
    @State var timeConsumed: Date = Date()

    init(viewModel: AddEntryViewModel,
         showingAddEntryView: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingAddEntryView = showingAddEntryView
    }

    var body: some View {
        NavigationStack {
            List{
                if !searchText.isEmpty {
                    NavigationLink {
                        AddEntryInputFieldsView(viewModel: viewModel,
                                                defFoodDescription: searchText,
                                                defCalories: viewModel.defCaloriesFor(searchText),
                                                defTimeConsumed: $timeConsumed,
                                                searchText: $searchText)
                    } label: {
                        Text("Add \(searchText) as a new food").bold()
                    }
                }
                Section("Recent foods you've had at this time") {
                    ForEach(viewModel.getSuggestions(searchText: searchText), id: \.self) { suggestion in
                        NavigationLink {
                            AddEntryInputFieldsView(viewModel: viewModel,
                                                    defFoodDescription: suggestion.name,
                                                    defCalories: viewModel.defCaloriesFor(suggestion.name),
                                                    defTimeConsumed: $timeConsumed,
                                                    searchText: $searchText)
                        } label: {
                            Text(suggestion.name)
                        }
                        .listRowBackground(Colours.backgroundSecondary)
                    }
                }
            }
            MealItemsView(viewModel: MealItemsViewModel(foodEntries: viewModel.foodEntries))
            Spacer()
            .navigationTitle("Add new food")
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        self.showingAddEntryView = false
                    }
                }
            })
        }
        .font(.brand)
        .searchable(text: $searchText,
                     placement:  .navigationBarDrawer(displayMode: .always),
                     prompt: viewModel.prompt())
        .onSubmit(of: .search) {
            readyToNavigateToAddEntryInputFields = true
        }
        .navigationDestination(isPresented: $readyToNavigateToAddEntryInputFields) {
            AddEntryInputFieldsView(viewModel: viewModel,
                                    defFoodDescription: searchText,
                                    defCalories: viewModel.defCaloriesFor(searchText),
                                    defTimeConsumed: $timeConsumed,
                                    searchText: $searchText)
        }
    }
}

