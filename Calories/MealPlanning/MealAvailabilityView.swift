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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.weekDates, id: \.self) { date in
                    DayMealSelectionView(date: date, viewModel: viewModel)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct ReasonTextField: View {
    let person: Person
    let date: Date
    let mealType: MealType
    @ObservedObject var viewModel: MealPlanningViewModel
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
                reasonText = viewModel.getReason(for: person, date: date, mealType: mealType)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .onChange(of: reasonText) { oldValue, newValue in
                guard !newValue.contains("\n") else {
                    isFocused = false
                    reasonText = newValue.replacing("\n", with: "")
                    viewModel.setReason(reasonText, for: person, date: date, mealType: mealType)
                    return
                }
                viewModel.setReason(newValue, for: person, date: date, mealType: mealType)
            }
            .onSubmit {
                isFocused = false
            }
    }
}

struct MealCardCompact: View {
    let mealType: MealType
    let date: Date
    @ObservedObject var viewModel: MealPlanningViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mealType.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Colours.foregroundPrimary)

            ForEach(Person.allCases, id: \.self) { person in
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(
                        isOn: binding(for: person)
                    ) {
                        Text(person.rawValue)
                            .font(.caption2)
                            .foregroundColor(Colours.foregroundPrimary)
                    }
                    .toggleStyle(CheckboxToggleStyle())

                    if !viewModel.isSelected(for: person, date: date, mealType: mealType) {
                        ReasonTextField(
                            person: person,
                            date: date,
                            mealType: mealType,
                            viewModel: viewModel
                        )
                    }
                }
            }
            Divider()
                .background(Colours.foregroundPrimary)
            Toggle(
                isOn: quickMealBinding
            ) {
                Text("Quick?")
                    .font(.caption2)
                    .foregroundColor(Colours.foregroundPrimary)
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colours.backgroundSecondary.opacity(0.5))
        .cornerRadius(8)
    }

    private func binding(for person: Person) -> Binding<Bool> {
        Binding(
            get: { viewModel.isSelected(for: person, date: date, mealType: mealType) },
            set: { _ in viewModel.toggleMealSelection(for: person, date: date, mealType: mealType) }
        )
    }

    private var quickMealBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isQuickMeal(for: date, mealType: mealType) },
            set: { viewModel.setQuickMeal($0, for: date, mealType: mealType) }
        )
    }
}

struct DayMealSelectionView: View {
    let date: Date
    @ObservedObject var viewModel: MealPlanningViewModel
    private let mealList: [MealType] = [.breakfast, .lunch, .dinner]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Colours.foregroundPrimary)

            HStack(alignment: .top, spacing: 8) {
                ForEach(mealList, id: \.self) { mealType in
                    MealCardCompact(
                        mealType: mealType,
                        date: date,
                        viewModel: viewModel
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let dayOfWeek = formatter.string(from: date)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        formatter.dateFormat = "MMM"
        let month = formatter.string(from: date)

        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        let dayWithSuffix = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"

        return "\(dayOfWeek) \(dayWithSuffix) \(month)"
    }
}
