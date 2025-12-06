//
//  MealAvailabilityView.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import SwiftUI

struct MealAvailabilityView: View {
    @ObservedObject var viewModel: MealPlanningViewModel

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    DayMealSelectionView(day: day, viewModel: viewModel)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .safeAreaPadding(.horizontal, 20)
        .padding(20)
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
    let day: DayOfWeek
    @ObservedObject var viewModel: MealPlanningViewModel
    private let mealList: [MealType] = [.breakfast, .lunch, .dinner]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(day.rawValue.capitalized)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Colours.foregroundPrimary)

            VStack(spacing: 12) {
                ForEach(mealList, id: \.self) { mealType in
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Text(mealType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Colours.foregroundPrimary)
                            ForEach([Person.tony, Person.karen], id: \.self) { person in
                                HStack(spacing: 5) {
                                    Toggle(
                                        isOn: Binding(
                                            get: {
                                                viewModel.isSelected(
                                                    for: person, day: day, mealType: mealType)
                                            },
                                            set: { _ in
                                                viewModel.toggleMealSelection(
                                                    for: person, day: day, mealType: mealType)
                                            }
                                        )
                                    ) {
                                        Text(person.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(Colours.foregroundPrimary)
                                    }
                                    .toggleStyle(CheckboxToggleStyle())
                                }
                            }
                        }
                        Image(systemName: "fork.knife")
                            .frame(width: 150, height: 120)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(10)
                    }

                }
            }
        }
        .padding(12)
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
    }
}
