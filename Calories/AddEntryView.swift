//
//  AddEntryView.swift
//  Calories
//
//  Created by Tony Short on 08/02/2023.
//

import Foundation
import SwiftUI

struct AddEntryView: View {
    private let viewModel: CaloriesViewModel
    @Environment(\.scenePhase) var scenePhase
    @State private var foodDescription: String = ""
    @State private var calories: Int = 0
    @State var timeConsumed: Date = Date()
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @Binding var totalCaloriesConsumed: Int

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }

    init(viewModel: CaloriesViewModel, totalCaloriesConsumed: Binding<Int>) {
        self.viewModel = viewModel
        _totalCaloriesConsumed = totalCaloriesConsumed
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                VStack {
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
                            TextField("", value: $calories, formatter: numberFormatter)
                                .frame(maxWidth: 60)
                                .focused($caloriesIsFocused)
                                .keyboardType(.numberPad)
                                .padding(5)
                                .background(.white)
                                .cornerRadius(10)
                                .foregroundColor(.black)
                        }
                    }
                    DatePicker("Time consumed", selection: $timeConsumed, displayedComponents: .hourAndMinute)

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
                    .onChange(of: scenePhase) { newPhase in
                        if CaloriesViewModel.shouldClearFields(phase: newPhase, date: timeConsumed) {
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
            .navigationTitle("Add new food")
        }
    }
}
