//
//  MealAvailabilityView.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import SwiftUI

struct MealAvailabilityView: View {
    @ObservedObject var viewModel: MealPlanningViewModel

    private let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Select which meals you'll need")
                .font(.title2)
                .foregroundColor(Colours.foregroundPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        DayMealSelectionView(day: day, viewModel: viewModel)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Colours.foregroundPrimary, lineWidth: 1)
                .frame(width: 16, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(configuration.isOn ? Color.accentColor : Color.clear)
                        .frame(width: 10, height: 10)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
    }
}

struct DayMealSelectionView: View {
    let day: String
    @ObservedObject var viewModel: MealPlanningViewModel
    private let mealList: [MealType] = [.breakfast, .lunch, .dinner]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Colours.foregroundPrimary)

            VStack(spacing: 8) {
                ForEach(mealList, id: \.self) { mealType in
                    HStack(spacing: 15) {
                        Text(mealType.shortened)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Colours.foregroundPrimary)
                        ForEach([Person.tony, Person.karen], id: \.self) { person in
                            HStack(spacing: 5) {
                                Toggle(isOn: Binding(
                                    get: { viewModel.isSelected(for: person, day: day, mealType: mealType) },
                                    set: { _ in viewModel.toggleMealSelection(for: person, day: day, mealType: mealType) }
                                )) {
                                    Text(person.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(Colours.foregroundPrimary)
                                }
                                .toggleStyle(CheckboxToggleStyle())
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
    }
}
