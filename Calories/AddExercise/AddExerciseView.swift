//
//  AddExerciseView.swift
//  Calories
//
//  Created by Tony Short on 16/02/2023.
//

import Foundation
import SwiftUI

struct AddExerciseView: View {
    private let viewModel: AddExerciseViewModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss
    @State private var exerciseDescription: String = ""
    @State private var calories: Int = 0
    @State private var timeExercised: Date = Date()
    @FocusState private var descriptionIsFocused: Bool
    @FocusState private var caloriesIsFocused: Bool
    @State private var isShowingFailureToAuthoriseAlert = false
    @Binding var showingAddExerciseView: Bool

    init(viewModel: AddExerciseViewModel,
         showingAddExerciseView: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingAddExerciseView = showingAddExerciseView
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack {
                VStack(spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Exercise")
                            TextField("Enter exercise...", text: $exerciseDescription)
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
                    VStack(alignment: .center) {
                        DatePicker("Time exercised", selection: $timeExercised, displayedComponents: .hourAndMinute)
                    }

                    Button {
                        Task {
                            do {
                                descriptionIsFocused = false
                                caloriesIsFocused = false
                                try await viewModel.addExercise(exerciseDescription: exerciseDescription,
                                                                calories: calories,
                                                                timeExercised: timeExercised)
                                exerciseDescription = ""
                                calories = 0
                                showingAddExerciseView = false
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
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding()
                .background(Colours.backgroundSecondary)
                .cornerRadius(10)
                Spacer()
                    .onChange(of: scenePhase) { newPhase in
                        if AddExerciseViewModel.shouldClearFields(phase: newPhase, date: timeExercised) {
                            Task {
                                exerciseDescription = ""
                                calories = 0
                                timeExercised = Date()
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
            .toolbar {
                ToolbarItem {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
