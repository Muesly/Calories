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
    @State private var readyToNavigate : Bool = false
    @Binding var showingAddEntryView: Bool

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
                                                defCalories: viewModel.defCaloriesFor(searchText))
                    } label: {
                        Text("Add \(searchText) as a new food").bold()
                    }
                }
                ForEach(viewModel.getSuggestions(searchText: searchText), id: \.self) { suggestion in
                    NavigationLink {
                        AddEntryInputFieldsView(viewModel: viewModel,
                                                defFoodDescription: suggestion.name,
                                                defCalories: viewModel.defCaloriesFor(suggestion.name))
                    } label: {
                        Text(suggestion.name)
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
        }.searchable(text: $searchText,
                     placement:  .navigationBarDrawer(displayMode: .always),
                     prompt: viewModel.prompt)
        .onSubmit(of: .search) {
            print("Searching")
            readyToNavigate = true
        }
        .navigationDestination(isPresented: $readyToNavigate) {
            AddEntryInputFieldsView(viewModel: viewModel,
                                    defFoodDescription: searchText,
                                    defCalories: viewModel.defCaloriesFor(searchText))
        }
    }
}


struct AddEntryInputFieldsView: View {
    private let viewModel: AddEntryViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State private var foodDescription: String = ""
    @State private var calories: Int = 0
    @State var timeConsumed: Date = Date()
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    private let defFoodDescription: String
    private let defCalories: Int

    init(viewModel: AddEntryViewModel,
         defFoodDescription: String,
         defCalories: Int) {
        self.viewModel = viewModel
        self.defFoodDescription = defFoodDescription
        self.defCalories = defCalories
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
                            Button {
                                UIApplication.shared.open(viewModel.calorieSearchURL(for: foodDescription))
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                    }
                }
                VStack(alignment: .center) {
                    Text("Time consumed")
                    DatePicker("", selection: $timeConsumed, displayedComponents: .hourAndMinute)
                                .frame(width: 80)
                }

                Button {
                    Task {
                        do {
                            descriptionIsFocused = false
                            caloriesIsFocused = false
                            try await viewModel.addFood(foodDescription: foodDescription,
                                                        calories: calories,
                                                        timeConsumed: timeConsumed)
                            foodDescription = ""
                            calories = 0
                            dismiss()
                        } catch {
                            isShowingFailureToAuthoriseAlert = true
                        }
                    }
                } label: {
                    Text("Add")
                        .foregroundColor(.blue)
                        .padding(10)
                }
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding()
            .background(Color("mintGreen").opacity(0.3))
            .cornerRadius(10)
            Spacer()
                .onAppear {
                    foodDescription = defFoodDescription
                    calories = defCalories
                }
                .onChange(of: scenePhase) { newPhase in
                    if AddEntryViewModel.shouldClearFields(phase: newPhase, date: timeConsumed) {
                        Task {
                            foodDescription = ""
                            calories = 0
                            timeConsumed = Date()
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
    }
}
