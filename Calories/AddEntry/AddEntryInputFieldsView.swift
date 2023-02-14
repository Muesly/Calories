//
//  AddEntryInputFieldsView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Foundation
import SwiftUI

struct AddEntryInputFieldsView: View {
    private let viewModel: AddEntryViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State private var foodDescription: String = ""
    @State private var calories: Int = 0
    @Binding var defTimeConsumed: Date
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    private let defFoodDescription: String
    private let defCalories: Int
    @Binding var searchText: String

    init(viewModel: AddEntryViewModel,
         defFoodDescription: String,
         defCalories: Int,
         defTimeConsumed: Binding<Date>,
         searchText: Binding<String>) {
        self.viewModel = viewModel
        self.defFoodDescription = defFoodDescription
        self.defCalories = defCalories
        self._defTimeConsumed = defTimeConsumed
        self._searchText = searchText
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
                    DatePicker("Time consumed", selection: $defTimeConsumed, displayedComponents: .hourAndMinute)
                }

                Button {
                    Task {
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
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding()
            .background(Colours.backgroundSecondary)
            .cornerRadius(10)
            Spacer()
            .onAppear {
                foodDescription = defFoodDescription
                calories = defCalories
            }
            .onChange(of: scenePhase) { newPhase in
                if AddEntryViewModel.shouldClearFields(phase: newPhase, date: defTimeConsumed) {
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
    }
}
