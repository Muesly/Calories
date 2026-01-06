//
//  MealPickerView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftData
import SwiftUI

struct MealPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @State var viewModel: MealPlanningViewModel
    let onSave: () -> Void
    @State private var swapMode = false
    @State private var mealToSwap: MealSelection?
    @Environment(\.dismiss) var dismiss
    @State var showCreateRecipe = false
    @State var mealForCreatedRecipe: MealSelection?

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.weekDates, id: \.self) { date in
                            DayMealSelectionView(date: date) { mealType, date in
                                if let meal = viewModel.meal(forDate: date, mealType: mealType) {
                                    RecipePickerCard(
                                        mealType: mealType,
                                        meal: meal,
                                        servingInfo: viewModel.servingInfo(
                                            for: date, mealType: mealType),
                                        isSwapMode: swapMode,
                                        isSelectedForSwap: mealToSwap?.id == meal.id,
                                        onRecipeSelected: { recipe in
                                            let person = meal.person
                                            viewModel.selectRecipe(
                                                recipe, for: person, date: date, mealType: mealType)
                                            swapMode = false
                                        },
                                        onCreateRecipe: {
                                            showCreateRecipe = true
                                            mealForCreatedRecipe = meal
                                        },
                                        onSwapRequested: {
                                            if swapMode && mealToSwap != nil {
                                                viewModel.swapMeals(mealToSwap!, with: meal)
                                                swapMode = false
                                                mealToSwap = nil
                                            } else {
                                                swapMode = true
                                                mealToSwap = meal
                                            }
                                        },
                                        onRemoveMeal: {
                                            let person = meal.person
                                            viewModel.clearMeal(
                                                for: person, date: date, mealType: mealType)
                                        },
                                        personSelections: personSelections(
                                            for: date, mealType: mealType),
                                        personReasons: personReasons(for: date, mealType: mealType),
                                        isQuickMeal: viewModel.isQuickMeal(
                                            for: date, mealType: mealType),
                                        onTogglePerson: { person in
                                            viewModel.toggleMealSelection(
                                                for: person, date: date, mealType: mealType)
                                        },
                                        onReasonChanged: { person, reason in
                                            viewModel.setReason(
                                                reason, for: person, date: date, mealType: mealType)
                                        },
                                        onQuickMealToggled: { isQuick in
                                            viewModel.setQuickMeal(
                                                isQuick, for: date, mealType: mealType)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveMealPlan()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if swapMode {
                        Button("Cancel Swap") {
                            swapMode = false
                            mealToSwap = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateRecipe) {
                if let meal = mealForCreatedRecipe {
                    CreateRecipeSheet(
                        isPresented: $showCreateRecipe,
                        mealType: meal.mealType,
                        onRecipeCreated: { recipe in
                            viewModel.selectRecipe(
                                recipe, for: meal.person, date: meal.date, mealType: meal.mealType)
                            swapMode = false
                            dismiss()
                        },
                        currentPage: AppFlags.showRecipeShortcut ? .details : .source,
                        extractedRecipeNames: AppFlags.showRecipeShortcut
                            ? ["Breakfast Muffin", "Next option"] : [],
                        dishPhoto: AppFlags.showRecipeShortcut ? UIImage(named: "Corn") : nil
                    )
                }
            }
            .task {
                if AppFlags.showRecipeShortcut {
                    showCreateRecipe = true
                    mealForCreatedRecipe = viewModel.meal(
                        forDate: viewModel.weekDates.first!, mealType: .breakfast)
                }
            }
        }
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

struct RecipePickerCard: View {
    let mealType: MealType
    let meal: MealSelection
    let servingInfo: String
    let isSwapMode: Bool
    let isSelectedForSwap: Bool
    let onRecipeSelected: (RecipeEntry) -> Void
    let onCreateRecipe: (() -> Void)
    let onSwapRequested: (() -> Void)
    let onRemoveMeal: (() -> Void)
    let personSelections: [Person: Bool]
    let personReasons: [Person: String]
    let isQuickMeal: Bool
    let onTogglePerson: (Person) -> Void
    let onReasonChanged: (Person, String) -> Void
    let onQuickMealToggled: (Bool) -> Void

    @State private var showMealChoice = false
    @State private var showRecipeBook = false
    @State private var showRecipeDetails = false
    @State private var showAvailability = false

    private var isNoMealRequired: Bool {
        servingInfo.hasPrefix("No meal required")
    }

    var body: some View {
        Button(action: {
            // In swap mode, clicking the card triggers swap
            if isSwapMode {
                onSwapRequested()
            } else if meal.recipe != nil {
                showRecipeDetails = true
            } else if !isNoMealRequired {
                showMealChoice = true
            }
        }) {
            ZStack(alignment: .topLeading) {
                // Use an empty MealCard for styling
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(mealType.rawValue) \(mealType.iconName)")
                        .font(.subheadline)
                        .foregroundColor(Colours.foregroundPrimary)
                    Divider()
                        .background(Colours.foregroundPrimary)

                    if showAvailability {
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
                    } else {
                        if isNoMealRequired {
                            Text(servingInfo)
                                .font(.caption)
                                .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                                .italic()
                        } else {
                            Text(meal.recipe?.name ?? "Choose a meal")
                                .font(.caption)
                                .foregroundColor(Colours.foregroundPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(minHeight: 32, alignment: .top)

                            Divider()
                                .background(Colours.foregroundPrimary)
                        }
                    }

                    HStack {
                        Text(servingInfo)
                            .font(.caption2)
                            .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                        Spacer()
                        if !isSwapMode {
                            Menu {
                                if showAvailability {
                                    Button(action: {
                                        showAvailability = false
                                    }) {
                                        Label("Meal Pick", systemImage: "pencil")
                                    }
                                } else {
                                    Button(action: {
                                        showRecipeBook = true
                                    }) {
                                        Label("Change", systemImage: "pencil")
                                    }
                                    Button(action: onSwapRequested) {
                                        Label("Swap", systemImage: "arrow.left.arrow.right")
                                    }
                                    Button(action: {
                                        showAvailability = true
                                    }) {
                                        Label("Availability", systemImage: "person.2")
                                    }
                                    if meal.recipe != nil {
                                        Button(role: .destructive, action: onRemoveMeal) {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                                    .padding(8)
                            }
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 140)
                .background(
                    isSelectedForSwap
                        ? Colours.backgroundSecondary
                        : Colours.backgroundSecondary.opacity(0.5)
                )
                .cornerRadius(8)
                .overlay(
                    isSelectedForSwap
                        ? RoundedRectangle(cornerRadius: 8)
                            .stroke(Colours.foregroundPrimary, lineWidth: 2)
                        : nil
                )
            }
        }
        .sheet(isPresented: $showRecipeDetails) {
            if let recipe = meal.recipe {
                RecipeDetailsDisplayView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showMealChoice) {
            if let recipe = meal.recipe {
                MealChoiceView(
                    recipe: recipe,
                    mealType: mealType,
                    servingInfo: servingInfo
                )
            } else {
                RecipeBookView(
                    mealType: mealType,
                    onRecipeSelected: onRecipeSelected,
                    onCreateRecipe: onCreateRecipe
                )
            }
        }
        .sheet(isPresented: $showRecipeBook) {
            RecipeBookView(
                mealType: mealType,
                onRecipeSelected: onRecipeSelected,
                onCreateRecipe: onCreateRecipe
            )
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
