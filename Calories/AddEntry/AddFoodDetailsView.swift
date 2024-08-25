//
//  AddFoodDetailsView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Foundation
import SwiftUI

struct AddFoodDetailsView: View {
    private let viewModel: AddFoodViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State var foodDescription: String
    @State var calories: Int = 0
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @State private var showingAddPlantView = false
    let foodTemplate: FoodEntry?
    @State var foodAddedAtTime: Date
    @State var addedPlant: String = ""
    @Binding var addedFoodEntry: FoodEntry?
    @Binding var isFoodItemsViewPresented: Bool

    init(viewModel: AddFoodViewModel,
         foodTemplate: FoodEntry?,
         addedFoodEntry: Binding<FoodEntry?>,
         isFoodItemsViewPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.foodTemplate = foodTemplate
        _foodDescription = State(initialValue: foodTemplate?.foodDescription ?? "")
        _calories = State(initialValue: Int(foodTemplate?.calories ?? 0))
        _addedFoodEntry = addedFoodEntry
        _foodAddedAtTime = State(initialValue: foodTemplate?.timeConsumed ?? Date())
        _isFoodItemsViewPresented = isFoodItemsViewPresented
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
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
                            TextField("", value: $calories, formatter: numberFormatter)
                                .frame(maxWidth: 60)
                                .focused($caloriesIsFocused)
                                .keyboardType(.numberPad)
                                .padding(5)
                                .background(.white)
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .accessibilityIdentifier("Calories Number Field")
                            Button {
                                UIApplication.shared.open(viewModel.calorieSearchURL(for: foodDescription))
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                    }
                }
                MealPickerView(viewModel: MealPickerViewModel(timeConsumed: $foodAddedAtTime))

                List {
                    Section {
                        ForEach(viewModel.plants) {
                            Text($0.name)
                        }
                        Button("Add new plant") {
                            showingAddPlantView = true
                        }
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
                }
                .accessibilityIdentifier("Food's Plant List")
                .listStyle(.plain)

                Button {
                    Task(priority: .high) {
                        do {
                            descriptionIsFocused = false
                            caloriesIsFocused = false
                            addedFoodEntry = try await viewModel.addFood(foodDescription: foodDescription,
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
            }
            .padding()
            .background(Colours.backgroundSecondary)
            .cornerRadius(10)
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
        .padding()
        .cornerRadius(10)
        .font(.brand)
        .sheet(isPresented: $showingAddPlantView) {
            AddPlantView(addedPlant: $addedPlant)
        }
        .task {
            viewModel.plants = (foodTemplate?.plants ?? []).map { Plant(name: $0.name) }
        }
        .onChange(of: addedPlant) { _, newValue in
            viewModel.addPlant(newValue)
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddFoodDetailsView(viewModel: AddFoodViewModel(healthStore: StubbedHealthStore(),
                                                   modelContext: modelContext),
                       foodTemplate: .init(foodDescription: "Some food",
                                           calories: 100,
                                           timeConsumed: Date(),
                                           plants: [.init("Plant 1"), .init("Plant 2")]),
                       addedFoodEntry: .constant(nil),
                       isFoodItemsViewPresented: .constant(true))
}

struct Plant: Identifiable {
    var id: String { name }
    let name: String
}
