//
//  AddEntryView.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    private var viewModel: AddEntryViewModel
    @State var searchText = ""
    @State var foodAdded = false
    @State private var readyToNavigateToAddEntryInputFields: Bool = false
    @Binding var showingAddEntryView: Bool
    @State private var newEntryAdded: Bool = false
    @State var timeConsumed: Date = Date()
    private let mealItemsViewModel: MealItemsViewModel

    init(viewModel: AddEntryViewModel,
         showingAddEntryView: Binding<Bool>,
         currentDate: Date = Date()) {
        self.viewModel = viewModel
        self._showingAddEntryView = showingAddEntryView
        self.mealItemsViewModel = MealItemsViewModel(viewContext: viewModel.container.viewContext,
                                                     currentDate: currentDate)
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    NavigationLink {
                        AddEntryInputFieldsView(viewModel: viewModel,
                                                defFoodDescription: searchText,
                                                defCalories: viewModel.defCaloriesFor(searchText),
                                                defTimeConsumed: $timeConsumed,
                                                searchText: $searchText,
                                                foodAdded: $foodAdded)
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
                                                    searchText: $searchText,
                                                    foodAdded: $foodAdded)
                        } label: {
                            Text(suggestion.name)
                        }
                        .listRowBackground(Colours.backgroundSecondary)
                    }
                }
            }
            MealItemsView(viewModel: mealItemsViewModel)
            Spacer()
            .navigationTitle("Add new food")
            .toolbar {
                ToolbarItem {
                    Button("Close") {
                        self.showingAddEntryView = false
                    }
                }
            }
            .onChange(of: foodAdded) { foodAdded in
                mealItemsViewModel.fetchMealFoodEntries()
            }
        }
        .font(.brand)
        .searchable(text: $searchText,
                     placement:  .navigationBarDrawer(displayMode: .always),
                     prompt: viewModel.prompt())
        .onSubmit(of: .search) {
            dismissSearch()
            readyToNavigateToAddEntryInputFields = true
        }
        .navigationDestination(isPresented: $readyToNavigateToAddEntryInputFields) {
            AddEntryInputFieldsView(viewModel: viewModel,
                                    defFoodDescription: searchText,
                                    defCalories: viewModel.defCaloriesFor(searchText),
                                    defTimeConsumed: $timeConsumed,
                                    searchText: $searchText,
                                    foodAdded: $foodAdded)
        }
    }
}

