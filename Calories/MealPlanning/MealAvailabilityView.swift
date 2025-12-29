//
//  MealAvailabilityView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftUI

/// Reusable card component for meal-related UI
struct MealCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 140)
        .background(Colours.backgroundSecondary.opacity(0.5))
        .cornerRadius(8)
    }
}

struct MealAvailabilityView: View {
    @ObservedObject var viewModel: MealPlanningViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.weekDates, id: \.self) { date in
                    DayMealSelectionView(date: date) { mealType, date in
                        MealAvailabilityCard(
                            mealType: mealType,
                            personSelections: personSelections(for: date, mealType: mealType),
                            personReasons: personReasons(for: date, mealType: mealType),
                            isQuickMeal: viewModel.isQuickMeal(for: date, mealType: mealType),
                            onTogglePerson: { person in
                                viewModel.toggleMealSelection(
                                    for: person, date: date, mealType: mealType)
                            },
                            onReasonChanged: { person, reason in
                                viewModel.setReason(
                                    reason, for: person, date: date, mealType: mealType)
                            },
                            onQuickMealToggled: { isQuick in
                                viewModel.setQuickMeal(isQuick, for: date, mealType: mealType)
                            }
                        )
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func personSelections(for date: Date, mealType: MealType) -> [Person: Bool] {
        var selections: [Person: Bool] = [:]
        for person in Person.allCases {
            selections[person] = viewModel.isSelected(for: person, date: date, mealType: mealType)
        }
        return selections
    }

    private func personReasons(for date: Date, mealType: MealType) -> [Person: String] {
        var reasons: [Person: String] = [:]
        for person in Person.allCases {
            reasons[person] = viewModel.getReason(for: person, date: date, mealType: mealType)
        }
        return reasons
    }
}

struct ReasonTextField: View {
    let person: Person
    let initialReason: String
    let onReasonChanged: (String) -> Void
    @State private var reasonText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Reason...", text: $reasonText, axis: .vertical)
            .font(.caption2)
            .submitLabel(.done)
            .lineLimit(2)
            .foregroundColor(Colours.foregroundPrimary)
            .padding(4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
            .focused($isFocused)
            .onAppear {
                reasonText = initialReason
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .onChange(of: reasonText) { oldValue, newValue in
                guard !newValue.contains("\n") else {
                    isFocused = false
                    reasonText = newValue.replacing("\n", with: "")
                    onReasonChanged(reasonText)
                    return
                }
                onReasonChanged(newValue)
            }
            .onSubmit {
                isFocused = false
            }
    }
}

struct MealAvailabilityCard: View {
    let mealType: MealType
    let personSelections: [Person: Bool]
    let personReasons: [Person: String]
    let isQuickMeal: Bool
    let onTogglePerson: (Person) -> Void
    let onReasonChanged: (Person, String) -> Void
    let onQuickMealToggled: (Bool) -> Void

    var body: some View {
        MealCard {
            Text("\(mealType.rawValue) \(mealType.iconName)")
                .font(.subheadline)
                .foregroundColor(Colours.foregroundPrimary)
            Divider()
                .background(Colours.foregroundPrimary)

            ForEach(Person.allCases, id: \.self) { person in
                let isSelected = personSelections[person] ?? true
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: binding(for: person, isSelected: isSelected)) {
                        Text(person.rawValue)
                            .font(.caption2)
                            .foregroundColor(Colours.foregroundPrimary)
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    if !isSelected {
                        ReasonTextField(
                            person: person,
                            initialReason: personReasons[person] ?? "",
                            onReasonChanged: { reason in
                                onReasonChanged(person, reason)
                            }
                        )
                    }
                }
            }
            Divider()
                .background(Colours.foregroundPrimary)
            Toggle(isOn: quickMealBinding) {
                Text("Quick?")
                    .font(.caption2)
                    .foregroundColor(Colours.foregroundPrimary)
            }
            .toggleStyle(CheckboxToggleStyle())
        }
    }

    private func binding(for person: Person, isSelected: Bool) -> Binding<Bool> {
        Binding(
            get: { isSelected },
            set: { _ in onTogglePerson(person) }
        )
    }

    private var quickMealBinding: Binding<Bool> {
        Binding(
            get: { isQuickMeal },
            set: { onQuickMealToggled($0) }
        )
    }
}
