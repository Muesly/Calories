//
//  AddExerciseInputFieldsView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Foundation
import SwiftUI

struct AddExerciseDetailsView: View {
    private let viewModel: AddExerciseViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State var exerciseDescription: String
    @State var calories: Int = 0
    @Binding var defTimeConsumed: Date
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    private let defExerciseDescription: String
    let defCalories: Int
    @Binding var searchText: String
    @Binding var exerciseAdded: Bool

    init(viewModel: AddExerciseViewModel,
         defExerciseDescription: String,
         defCalories: Int,
         defTimeConsumed: Binding<Date>,
         searchText: Binding<String>,
         exerciseAdded: Binding<Bool>) {
        self.viewModel = viewModel
        self.defExerciseDescription = defExerciseDescription
        self.defCalories = defCalories
        _defTimeConsumed = defTimeConsumed
        _searchText = searchText
        _exerciseDescription = State(initialValue: defExerciseDescription)
        _calories = State(initialValue: defCalories)
        _exerciseAdded = exerciseAdded
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
                        Text("Exercise")
                        TextField("Enter exercise", text: $exerciseDescription)
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
                        }
                    }
                }
 
                Button {
                    Task(priority: .high) {
                        do {
                            descriptionIsFocused = false
                            caloriesIsFocused = false
                            try await viewModel.addExercise(exerciseDescription: exerciseDescription,
                                                            calories: calories,
                                                            timeExercised: defTimeConsumed)
                            exerciseDescription = ""
                            calories = 0
                            searchText = ""
                            dismiss()
                            exerciseAdded = true
                        } catch {
                            isShowingFailureToAuthoriseAlert = true
                        }
                    }
                } label: {
                    Text("Add \(exerciseDescription)")
                        .padding(10)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .disabled(calories == 0 || exerciseDescription.isEmpty)
            }
            .padding()
            .background(Colours.backgroundSecondary)
            .cornerRadius(10)
            Spacer()
                .onChange(of: scenePhase) { _, newPhase in
                    if AddFoodViewModel.shouldClearFields(phase: newPhase, date: defTimeConsumed) {
                        Task {
                            exerciseDescription = ""
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
    }
}

#Preview {
    AddExerciseDetailsView(viewModel: AddExerciseViewModel(healthStore: StubbedHealthStore(),
                                                               modelContext: .inMemory),
                               defExerciseDescription: "Some exercise",
                               defCalories: 100,
                               defTimeConsumed: .constant(Date()),
                               searchText: .constant("Some exercise"),
                               exerciseAdded: .constant(false))
}
