//
//  AddFoodDetailsView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Foundation
import SwiftUI

struct AddFoodDetailsView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: AddFoodViewModel
    @State var foodDescription: String
    @State var calories: Int = 0
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @State private var showingAddPlantView = false
    @State var foodTemplate: FoodTemplate
    @State var foodAddedAtTime: Date
    @State var addedPlant: String = ""
    @Binding var addedFoodEntry: FoodEntry?
    @Binding var isFoodItemsViewPresented: Bool

    init(viewModel: AddFoodViewModel,
         foodTemplate: FoodTemplate,
         addedFoodEntry: Binding<FoodEntry?>,
         isFoodItemsViewPresented: Binding<Bool>) {
        self.viewModel = viewModel
        _foodTemplate = State(initialValue: foodTemplate)
        _foodDescription = State(initialValue: foodTemplate.description)
        _calories = State(initialValue: foodTemplate.calories)
        _addedFoodEntry = addedFoodEntry
        _foodAddedAtTime = State(initialValue: foodTemplate.dateTime)
        _isFoodItemsViewPresented = isFoodItemsViewPresented
    }

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Food")
                        TextField("Enter food or drink...", text: $foodDescription)
                            .focused($descriptionIsFocused)
                            .padding(5)
                            .background(.white)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                    }
                    VStack(alignment: .leading) {
                        Text("Calories")
                        HStack {
                            TextField("", value: $calories, formatter: .integer)
                                .frame(maxWidth: 60)
                                .focused($caloriesIsFocused)
                                .keyboardType(.numberPad)
                                .padding(5)
                                .background(.white)
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .accessibilityIdentifier("Calories Number Field")
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            caloriesIsFocused = false
                                        }
                                        .fontWeight(.bold)
                                    }
                                }
                            Button {
                                UIApplication.shared.open(viewModel.calorieSearchURL(for: foodDescription))
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                    }
                }
                MealPickerView(viewModel: MealPickerViewModel(timeConsumed: $foodAddedAtTime))
            }
            .padding()
            .background(Colours.backgroundSecondary)
            .cornerRadius(10)
            .padding(20)

            List {
                Section {
                    PlantGrid(plants: viewModel.plants.map { $0.name },
                              added: { _ in })
                } header: {
                    HStack {
                        Text("Plants")
                        Spacer()
                        Button("Add +") {
                            showingAddPlantView = true
                        }.accessibilityIdentifier("Add Plant Header Button")
                    }
                }
                .listSectionSeparator(.hidden, edges: .top)
                .listRowBackground(Colours.backgroundSecondary)
            }
            .accessibilityIdentifier("Food's Plant List")
            .cornerRadius(10)

            Button {
                Task(priority: .high) {
                    do {
                        descriptionIsFocused = false
                        caloriesIsFocused = false
                        addedFoodEntry = try await viewModel.addFood(
                            foodDescription: foodDescription,
                            calories: calories,
                            timeConsumed: foodAddedAtTime,
                            plants: viewModel.plants)
                        foodDescription = ""
                        calories = 0
                        self.isFoodItemsViewPresented = false
                        dismiss()
                    } catch {
                        isShowingFailureToAuthoriseAlert = true
                    }
                }
            } label: {
                Text("Add \(foodDescription)")
                    .padding(10)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(calories == 0 || foodDescription.isEmpty)
            Spacer()
                .onChange(of: scenePhase) { _, newPhase in
                    if AddFoodViewModel.shouldClearFields(phase: newPhase, date: foodAddedAtTime) {
                        Task {
                            foodDescription = ""
                            calories = 0
                        }
                    }
                }
                .alert("Failed to access vehicle health",
                       isPresented: $isShowingFailureToAuthoriseAlert) {
                    Button("OK", role: .cancel) {}
                }
        }
        .cornerRadius(10)
        .font(.brand)
        .sheet(isPresented: $showingAddPlantView) {
            let viewModel = AddPlantViewModel(modelContext: modelContext)
            AddPlantView(viewModel: viewModel, addedPlant: $addedPlant)
        }
        .task {
            viewModel.plants = foodTemplate.plants.map { Plant(name: $0) }
        }
        .onChange(of: addedPlant) { _, newValue in
            if !newValue.isEmpty {
                viewModel.addPlant(newValue)
            }
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddFoodDetailsView(viewModel: AddFoodViewModel(healthStore: StubbedHealthStore(),
                                                   modelContext: modelContext),
                       foodTemplate: .init(description: "Some food",
                                           calories: 100),
                       addedFoodEntry: .constant(nil),
                       isFoodItemsViewPresented: .constant(true))
}

struct Plant: Identifiable {
    var id: String { name }
    let name: String
}
