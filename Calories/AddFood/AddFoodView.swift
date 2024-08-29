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
    
    private let viewModel: AddFoodViewModel
    private var mealItemsViewModel: MealItemsViewModel
    @State var searchText = ""
    @State var template: FoodTemplate?
    @State var addedFoodEntry: FoodEntry?
    @State var timeConsumed: Date

    @Binding var showingAddEntryView: Bool
    @State private var showingAddFoodDetailsView: Bool = false

    init(viewModel: AddFoodViewModel,
         showingAddEntryView: Binding<Bool>,
         timeConsumed: Date = Date()) {
        self.viewModel = viewModel
        self.timeConsumed = timeConsumed
        self._showingAddEntryView = showingAddEntryView
        self.mealItemsViewModel = MealItemsViewModel(modelContext: viewModel.modelContext,
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
                                template = viewModel.foodTemplateFor(suggestion.name, timeConsumed: timeConsumed)
                                showingAddFoodDetailsView = true
                            } label: {
                                Text(suggestion.name)
                            }
                            .listRowBackground(Colours.backgroundSecondary)
                        }
                    }
                }
                .foregroundColor(.white)
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
                template = viewModel.foodTemplateFor(searchText, timeConsumed: timeConsumed)
            }
            .navigationDestination(isPresented: $showingAddFoodDetailsView) {
                if let template {
                    addFoodInputFieldsView(template: template)
                }
            }
        }
        .font(.brand)
        .searchable(text: $searchText,
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

    private func addFoodInputFieldsView(template: FoodTemplate) -> AddFoodDetailsView {
        AddFoodDetailsView(viewModel: viewModel,
                           foodTemplate: template,
                           addedFoodEntry: $addedFoodEntry,
                           isFoodItemsViewPresented: $showingAddFoodDetailsView)
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddFoodView(viewModel: .init(healthStore: MockHealthStore(),
                                 modelContext: modelContext),
                showingAddEntryView: .constant(false),
                timeConsumed: Date())
}
