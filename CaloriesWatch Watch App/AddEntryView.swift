//
//  AddEntryView.swift
//  CaloriesWatch Watch App
//
//  Created by Tony Short on 16/02/2023.
//

import SwiftUI

struct AddEntryView: View {
    private let viewModel: AddEntryViewModel
    @State var showingAddEntryView = false
    @State var showingAddExerciseView = false
    @State private var calories: Int = 0
    @State var newExerciseEntry: Int = 0
    @State var newFoodEntry: Int = 0

    init(viewModel: AddEntryViewModel = .init()) {
        self.viewModel = viewModel
    }

    var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.zeroSymbol = ""
        return formatter
    }

    var body: some View {
        VStack {
            Button {
                showingAddExerciseView = true
            } label: {
                Text("Add exercise").font(.brand)
                    .padding(10)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button {
                showingAddEntryView = true
            } label: {
                Text("Add food").font(.brand)
                    .padding(10)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(isPresented: $showingAddEntryView) {
            NumberPadView(number: $newFoodEntry)
        }
        .sheet(isPresented: $showingAddExerciseView) {
            NumberPadView(number: $newExerciseEntry)
        }
        .onChange(of: newFoodEntry) { calories in
            Task {
                try await viewModel.addFood(calories: calories, timeConsumed: Date())
            }
        }
        .onChange(of: newExerciseEntry) { calories in
            Task {
                try await viewModel.addExercise(calories: calories, timeExercised: Date())
            }
        }
    }
}
