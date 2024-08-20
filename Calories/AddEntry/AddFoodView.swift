//
//  AddFoodView.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismissSearch) private var dismissSearch
    private var viewModel: AddFoodViewModel
    @State var searchText = ""
    @State var foodAddedAtTime: Date?
    @State private var readyToNavigateToAddFoodInputFields: Bool = false
    @Binding var showingAddEntryView: Bool
    @State var timeConsumed: Date = Date()
    private var mealItemsViewModel: MealItemsViewModel

    init(viewModel: AddFoodViewModel,
         showingAddEntryView: Binding<Bool>,
         currentDate: Date = Date()) {
        self.viewModel = viewModel
        self._showingAddEntryView = showingAddEntryView
        self.mealItemsViewModel = MealItemsViewModel(viewContext: viewModel.viewContext,
                                                     currentDate: currentDate)
    }

    var body: some View {
        NavigationStack {
            List {
                if !searchText.isEmpty {
                    NavigationLink {
                        addFoodInputFieldsView(description: searchText)
                    } label: {
                        Text("Add \(searchText) as a new food").bold()
                    }
                }
                Section("Recent foods you've had at this time") {
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        NavigationLink {
                            addFoodInputFieldsView(description: suggestion.name)
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
            .navigationDestination(isPresented: $readyToNavigateToAddFoodInputFields) {
                addFoodInputFieldsView(description: searchText)
            }
        }
        .font(.brand)
        .searchable(text: $searchText,
                    placement:  .navigationBarDrawer(displayMode: .always),
                    prompt: viewModel.prompt(for: timeConsumed))
        .onSubmit(of: .search) {
            dismissSearch()
            readyToNavigateToAddFoodInputFields = true
        }
        .onChange(of: foodAddedAtTime) { _, foodAddedAtTime in
            mealItemsViewModel.fetchMealFoodEntries()
            if let foodAddedAtTime {
                timeConsumed = foodAddedAtTime
                viewModel.setDateForEntries(timeConsumed)
                viewModel.fetchSuggestions(searchText: searchText)
                mealItemsViewModel.currentDate = timeConsumed
                mealItemsViewModel.fetchMealFoodEntries()
                dismissSearch()
            }
        }
    }

    private func addFoodInputFieldsView(description: String) -> AddFoodDetailsView {
        AddFoodDetailsView(viewModel: viewModel,
                               defFoodDescription: description,
                               defCalories: viewModel.defCaloriesFor(description),
                               defTimeConsumed: $timeConsumed,
                               searchText: $searchText,
                               foodAddedAtTime: $foodAddedAtTime)
    }
}

#Preview {
    AddFoodView(viewModel: .init(healthStore: MockHealthStore(),
                                 viewContext: PersistenceController.inMemoryContext),
                 showingAddEntryView: .constant(false),
                 currentDate: Date())
}
