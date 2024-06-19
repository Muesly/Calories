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
    @ObservedObject private var viewModel: AddEntryViewModel
    @State var searchText = ""
    @State var foodAddedAtTime: Date?
    @State private var readyToNavigateToAddEntryInputFields: Bool = false
    @Binding var showingAddEntryView: Bool
    @State private var newEntryAdded: Bool = false
    @State var timeConsumed: Date = Date()
    @ObservedObject private var mealItemsViewModel: MealItemsViewModel

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
                                                foodAddedAtTime: $foodAddedAtTime)
                    } label: {
                        Text("Add \(searchText) as a new food").bold()
                    }
                }
                Section("Recent foods you've had at this time") {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        NavigationLink {
                            AddEntryInputFieldsView(viewModel: viewModel,
                                                    defFoodDescription: suggestion.name,
                                                    defCalories: viewModel.defCaloriesFor(suggestion.name),
                                                    defTimeConsumed: $timeConsumed,
                                                    searchText: $searchText,
                                                    foodAddedAtTime: $foodAddedAtTime)
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
            .onAppear {
                viewModel.fetchSuggestions(searchText: searchText)
            }
            .onChange(of: searchText) { searchText in
                viewModel.fetchSuggestions(searchText: searchText)
            }
            .onChange(of: foodAddedAtTime) { foodAddedAtTime in
                mealItemsViewModel.fetchMealFoodEntries()
                if let foodAddedAtTime {
                    timeConsumed = foodAddedAtTime
                    viewModel.setDateForEntries(timeConsumed)
                    viewModel.fetchSuggestions(searchText: searchText)
                    mealItemsViewModel.currentDate = timeConsumed
                    mealItemsViewModel.fetchMealFoodEntries()
                }
            }
            .navigationDestination(isPresented: $readyToNavigateToAddEntryInputFields) {
                AddEntryInputFieldsView(viewModel: viewModel,
                                        defFoodDescription: searchText,
                                        defCalories: viewModel.defCaloriesFor(searchText),
                                        defTimeConsumed: $timeConsumed,
                                        searchText: $searchText,
                                        foodAddedAtTime: $foodAddedAtTime)
            }
        }
        .font(.brand)
        .searchable(text: $searchText,
                    placement:  .navigationBarDrawer(displayMode: .always),
                    prompt: viewModel.prompt(for: timeConsumed))
        .onSubmit(of: .search) {
            dismissSearch()
            readyToNavigateToAddEntryInputFields = true
        }
    }
}

#Preview {
    AddEntryView(viewModel: .init(healthStore: MockHealthStore(),
                                  container: PersistenceController(inMemory: true).container), 
                 showingAddEntryView: .constant(false),
                 currentDate: Date())
}
