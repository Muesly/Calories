//
//  AddExerciseInputFieldsView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Foundation
import SwiftUI

struct AddExerciseDetailsView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @Environment(\.currentDate) var currentDate

    private let viewModel: AddExerciseViewModel
    @State var exerciseDescription: String
    @State var calories: Int = 0
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @Binding var timeExerciseAdded: Date?

    @Binding var isExerciseDetailsViewPresented: Bool

    init(
        viewModel: AddExerciseViewModel,
        exerciseTemplate: ExerciseEntry,
        timeExerciseAdded: Binding<Date?>,
        isExerciseDetailsViewPresented: Binding<Bool>
    ) {
        self.viewModel = viewModel
        _exerciseDescription = State(initialValue: exerciseTemplate.exerciseDescription)
        _calories = State(initialValue: Int(exerciseTemplate.calories))
        _isExerciseDetailsViewPresented = isExerciseDetailsViewPresented
        _timeExerciseAdded = timeExerciseAdded
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
                            TextField("", value: $calories, formatter: .integer)
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
                DatePicker(
                    "Date:",
                    selection: Binding(
                        get: {
                            viewModel.timeExercised
                        },
                        set: { newTime in
                            viewModel.timeExercised = newTime
                        }), displayedComponents: .date)

                Button {
                    Task(priority: .high) {
                        do {
                            descriptionIsFocused = false
                            caloriesIsFocused = false
                            _ = try await viewModel.addExercise(
                                exerciseDescription: exerciseDescription,
                                calories: calories,
                                timeExercised: viewModel.timeExercised)
                            timeExerciseAdded = viewModel.timeExercised
                            exerciseDescription = ""
                            calories = 0
                            dismiss()
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
                    if AddFoodViewModel.shouldClearFields(
                        phase: newPhase, date: viewModel.timeExercised)
                    {
                        Task {
                            exerciseDescription = ""
                            calories = 0
                            viewModel.timeExercised = currentDate
                        }
                    }
                }
                .alert(
                    "Failed to access vehicle health",
                    isPresented: $isShowingFailureToAuthoriseAlert
                ) {
                    Button("OK", role: .cancel) {}
                }
        }
        .padding()
        .cornerRadius(10)
        .font(.brand)
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var modelContext
    AddExerciseDetailsView(
        viewModel: AddExerciseViewModel(
            healthStore: StubbedHealthStore(),
            modelContext: .inMemory,
            timeExercised: Date()),
        exerciseTemplate: ExerciseEntry(
            exerciseDescription: "Some exercise",
            calories: 100,
            timeExercised: Date()),
        timeExerciseAdded: .constant(nil),
        isExerciseDetailsViewPresented: .constant(true))
}
