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
        VStack {
            HStack {
                TextField("Food", text: $foodDescription)
                    .focused($descriptionIsFocused)
                TextField("Calories", value: $calories, formatter: numberFormatter)
                    .focused($caloriesIsFocused)
                    .keyboardType(.numberPad)
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
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
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
        .background(Color("mintGreen").opacity(0.3))
        .cornerRadius(10)
    }
}
