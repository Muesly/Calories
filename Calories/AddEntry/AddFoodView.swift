//
//  AddFoodView.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import SwiftData
import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    
    private var viewModel: AddFoodViewModel
    private var mealItemsViewModel: MealItemsViewModel
    @State var searchText = ""
    @State var addedFoodEntry: FoodEntry?
    @State var timeConsumed: Date

    @Binding var showingAddEntryView: Bool
    @State private var showingAddFoodDetailsView: Bool = false
    @State private var isSearching: Bool = false

    init(viewModel: AddFoodViewModel,
         showingAddEntryView: Binding<Bool>,
         timeConsumed: Date = Date()) {
        self.viewModel = viewModel
        self.timeConsumed = timeConsumed
        self._showingAddEntryView = showingAddEntryView
        self.mealItemsViewModel = MealItemsViewModel(viewContext: viewModel.viewContext,
                                                     currentDate: timeConsumed)
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !searchText.isEmpty {
                        Button {
                            showingAddFoodDetailsView = true
                        } label: {
                            Text("Add \(searchText) as a new food").bold()
                        }
                    }
                    Section("Recent foods you've had at this time") {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                searchText = suggestion.name
                                showingAddFoodDetailsView = true
                            } label: {
                                Text(suggestion.name)
                            }
                            .listRowBackground(Colours.backgroundSecondary)
                        }
                    }
                }
                .accessibilityIdentifier("Food List")
                MealItemsView(viewModel: mealItemsViewModel)
                Spacer()
            }
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
            .onChange(of: searchText) { _, searchText in
                viewModel.fetchSuggestions(searchText: searchText)
            }
            .navigationDestination(isPresented: $showingAddFoodDetailsView) {
                addFoodInputFieldsView(description: searchText)
            }
        }
        .font(.brand)
        .searchable(text: $searchText,
                    isPresented: $isSearching,
                    placement:  .navigationBarDrawer(displayMode: .always),
                    prompt: viewModel.prompt(for: timeConsumed))
        .onSubmit(of: .search) {
            dismissSearch()
            showingAddFoodDetailsView = true
        }
        .onChange(of: showingAddFoodDetailsView) { _, isPresented in
            if !isPresented {
                searchText = ""
                dismissSearch()
                isSearching = false
            }
        }
        .onChange(of: addedFoodEntry) { _, addedFoodEntry in
            if let addedFoodEntry {
                mealItemsViewModel.fetchMealFoodEntries()
                timeConsumed = addedFoodEntry.timeConsumed
                viewModel.setDateForEntries(timeConsumed)
                mealItemsViewModel.currentDate = timeConsumed
            }
            viewModel.fetchSuggestions(searchText: searchText)
        }
    }

    private func addFoodInputFieldsView(description: String) -> AddFoodDetailsView {
        AddFoodDetailsView(viewModel: viewModel,
                           foodTemplate: viewModel.foodTemplateFor(description),
                           addedFoodEntry: $addedFoodEntry,
                           isFoodItemsViewPresented: $showingAddFoodDetailsView)
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddFoodView(viewModel: .init(healthStore: MockHealthStore(),
                                 viewContext: PersistenceController.inMemoryContext, modelContext: modelContext),
                showingAddEntryView: .constant(false),
                timeConsumed: Date())
}
