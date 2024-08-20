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
    @Binding var defTimeConsumed: Date
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @State private var showingAddPlantView = false
    private let defFoodDescription: String
    let defCalories: Int
    @Binding var searchText: String
    @Binding var foodAddedAtTime: Date?

    init(viewModel: AddFoodViewModel,
         defFoodDescription: String,
         defCalories: Int,
         defTimeConsumed: Binding<Date>,
         searchText: Binding<String>,
         foodAddedAtTime: Binding<Date?>) {
        self.viewModel = viewModel
        self.defFoodDescription = defFoodDescription
        self.defCalories = defCalories
        _defTimeConsumed = defTimeConsumed
        _searchText = searchText
        _foodDescription = State(initialValue: defFoodDescription)
        _calories = State(initialValue: defCalories)
        _foodAddedAtTime = foodAddedAtTime
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
                MealPickerView(viewModel: MealPickerViewModel(timeConsumed: $defTimeConsumed))

                List {
                    Section {
                        ForEach([Plant(name: "Lettuce")]) {
                            Text($0.name)
                        }
                        Button("Add new plant") {

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
                            try await viewModel.addFood(foodDescription: foodDescription,
                                                        calories: calories,
                                                        timeConsumed: defTimeConsumed)
                            foodDescription = ""
                            calories = 0
                            searchText = ""
                            dismiss()
                            foodAddedAtTime = defTimeConsumed
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
                    if AddFoodViewModel.shouldClearFields(phase: newPhase, date: defTimeConsumed) {
                        Task {
                            foodDescription = ""
                            calories = 0
                            defTimeConsumed = Date()
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
            AddPlantView()
        }
    }
}

#Preview {
    AddFoodDetailsView(viewModel: AddFoodViewModel(healthStore: StubbedHealthStore(),
                                                   viewContext: PersistenceController.inMemoryContext),
                           defFoodDescription: "Some food",
                           defCalories: 100,
                           defTimeConsumed: .constant(Date()),
                           searchText: .constant("Some food"),
                           foodAddedAtTime: .constant(Date()))
}

struct Plant: Identifiable {
    var id: String { name }
    let name: String
}
