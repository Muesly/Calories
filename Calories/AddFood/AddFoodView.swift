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
    @Environment(\.currentDate) var currentDate

    private let viewModel: AddFoodViewModel
    private var mealItemsViewModel: MealItemsViewModel
    @State var searchText = ""
    @State var template: FoodTemplate?
    @State var addedFoodEntry: FoodEntry?

    @Binding var showingAddEntryView: Bool
    @State private var showingAddFoodDetailsView: Bool = false

    init(
        viewModel: AddFoodViewModel,
        showingAddEntryView: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._showingAddEntryView = showingAddEntryView
        self.mealItemsViewModel = MealItemsViewModel(modelContext: viewModel.modelContext)
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
                        ForEach(viewModel.suggestions, id: \.name) { suggestion in
                            Button {
                                template = viewModel.foodTemplateFor(
                                    suggestion.name, timeConsumed: currentDate)
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
                Task {
                    await viewModel.fetchSuggestions(searchText: searchText)
                }
            }
            .onChange(of: searchText) { _, searchText in
                Task {
                    await viewModel.fetchSuggestions(searchText: searchText)
                    template = viewModel.foodTemplateFor(searchText, timeConsumed: currentDate)
                }
            }
            .navigationDestination(isPresented: $showingAddFoodDetailsView) {
                if let template {
                    addFoodInputFieldsView(template: template)
                }
            }
        }
        .font(.brand)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.prompt(for: currentDate)
        )
        .accessibilityIdentifier("Enter Food")
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
                let timeConsumed = addedFoodEntry.timeConsumed
                mealItemsViewModel.fetchMealFoodEntries(date: timeConsumed)
                viewModel.setDateForEntries(timeConsumed)
            }
            Task {
                await viewModel.fetchSuggestions(searchText: searchText)
            }
        }
    }

    private func addFoodInputFieldsView(template: FoodTemplate) -> AddFoodDetailsView {
        AddFoodDetailsView(
            viewModel: viewModel,
            foodTemplate: template,
            addedFoodEntry: $addedFoodEntry,
            isFoodItemsViewPresented: $showingAddFoodDetailsView)
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddFoodView(
        viewModel: .init(
            healthStore: MockHealthStore(),
            modelContext: modelContext),
        showingAddEntryView: .constant(false))
}
