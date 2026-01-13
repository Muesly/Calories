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
    @State private var swapMode = false
    @State private var dayMealToSwap: DayMeal?
    @Environment(\.dismiss) var dismiss
    @State var showCreateRecipe = false
    @State var mealForCreatedRecipe: MealSelection?

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.weekDates, id: \.self) { date in
                            DayMealSelectionView(date: date) { dayMeal in
                                let meals = viewModel.meals(forDayMeal: dayMeal)
                                RecipePickerCard(
                                    dayMeal: dayMeal,
                                    meals: meals,
                                    servingInfo: viewModel.servingInfo(forDayMeal: dayMeal),
                                    isSwapMode: swapMode,
                                    isSelectedForSwap: dayMealToSwap == dayMeal,
                                    onRecipeSelected: { recipe in
                                        if let meal = meals.first {
                                            let person = meal.person
                                            viewModel.selectRecipe(
                                                recipe, for: person, dayMeal: dayMeal)
                                            swapMode = false
                                        }
                                    },
                                    onCreateRecipe: {
                                        showCreateRecipe = true
                                        if let meal = meals.first {
                                            mealForCreatedRecipe = meal
                                        }
                                    },
                                    onSwapRequested: {
                                        if swapMode && dayMealToSwap != nil {
                                            viewModel.swapMeals(dayMealToSwap!, with: dayMeal)
                                            swapMode = false
                                            dayMealToSwap = nil
                                        } else {
                                            swapMode = true
                                            dayMealToSwap = dayMeal
                                        }
                                    },
                                    onRemoveMeal: {
                                        if let meal = meals.first {
                                            let person = meal.person
                                            viewModel.clearMeal(for: person, dayMeal: dayMeal)
                                        }
                                    },
                                    personSelections: personSelections(dayMeal: dayMeal),
                                    personReasons: personReasons(dayMeal: dayMeal),
                                    isQuickMeal: viewModel.isQuickMeal(forDayMeal: dayMeal),
                                    isPinned: viewModel.isPinnedMeal(forDayMeal: dayMeal),
                                    onTogglePerson: { person in
                                        viewModel.toggleMealSelection(
                                            for: person, dayMeal: dayMeal)
                                    },
                                    onReasonChanged: { person, reason in
                                        viewModel.setReason(
                                            reason, for: person, dayMeal: dayMeal)
                                    },
                                    onQuickMealToggled: { isQuick in
                                        viewModel.setQuickMeal(
                                            isQuick, dayMeal: dayMeal)
                                    },
                                    onPinnedToggled: { isPinned in
                                        viewModel.setPinnedMeal(
                                            isPinned, dayMeal: dayMeal)
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
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.goToPreviousWeek() }) {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.goToNextWeek() }) {
                        Image(systemName: "chevron.right")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if swapMode {
                        Button("Cancel Swap") {
                            swapMode = false
                            dayMealToSwap = nil
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateRecipe) {
                if let meal = mealForCreatedRecipe {
                    CreateRecipeSheet(
                        isPresented: $showCreateRecipe,
                        mealType: meal.dayMeal.mealType,
                        onRecipeCreated: { recipe in
                            viewModel.selectRecipe(
                                recipe, for: meal.person, dayMeal: meal.dayMeal)
                            swapMode = false
                            showCreateRecipe = false
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
                    mealForCreatedRecipe = viewModel.meals(
                        forDayMeal: .init(mealType: .breakfast, date: viewModel.weekDates.first!)
                    ).first!
                }
            }
        }
    }

    private func personSelections(dayMeal: DayMeal) -> [Person: Bool] {
        var selections: [Person: Bool] = [:]
        for person in Person.allCases {
            selections[person] = viewModel.isSelected(for: person, dayMeal: dayMeal)
        }
        return selections
    }

    private func personReasons(dayMeal: DayMeal) -> [Person: String] {
        var reasons: [Person: String] = [:]
        for person in Person.allCases {
            reasons[person] = viewModel.getReason(for: person, dayMeal: dayMeal)
        }
        return reasons
    }
}

struct RecipePickerCard: View {
    let dayMeal: DayMeal
    let meals: [MealSelection]
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
    let isPinned: Bool
    let onTogglePerson: (Person) -> Void
    let onReasonChanged: (Person, String) -> Void
    let onQuickMealToggled: (Bool) -> Void
    let onPinnedToggled: (Bool) -> Void

    //    private var meal: MealSelection {
    //        meals.first!
    //    }

    private var mealType: MealType {
        dayMeal.mealType
    }

    @State private var showMealChoice = false
    @State private var showRecipeBook = false
    @State private var showRecipeDetails = false
    @State private var showAvailability = false

    private var isNoMealRequired: Bool {
        servingInfo.hasPrefix("No meal required")
    }

    private var mealsHaveARecipe: Bool {
        meals.count { $0.recipe != nil } > 0
    }

    private var firstRecipe: RecipeEntry? {
        meals.first(where: { $0.recipe != nil })?.recipe
    }

    var body: some View {
        Button(action: {
            // In swap mode, clicking the card triggers swap
            if isSwapMode {
                onSwapRequested()
            } else if mealsHaveARecipe {
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
                            let selectedPeople = Person.allCases.filter {
                                personSelections[$0] ?? true
                            }
                            let recipesAreDifferent = areRecipesDifferent(selectedPeople)

                            if recipesAreDifferent {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(selectedPeople, id: \.self) { person in
                                        //                                        guard let meal = meals.first(where: { $0.person == person }) else {
                                        //                                            continue
                                        //                                        }
                                        //                                        let recipeName = firstRecipe?.name ?? "Choose a meal"
                                        //                                        let displayText = "\(recipeName) (\(person.rawValue))"
                                        //                                        Text(displayText)
                                        //                                            .font(.caption)
                                        //                                            .foregroundColor(Colours.foregroundPrimary)
                                        //                                            .lineLimit(3)
                                        //                                            .multilineTextAlignment(.leading)
                                        //                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .frame(minHeight: 32, alignment: .top)
                            } else {
                                let recipeName = firstRecipe?.name ?? "Choose a meal"
                                Text(recipeName)
                                    .font(.caption)
                                    .foregroundColor(Colours.foregroundPrimary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 32, alignment: .top)
                            }

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
                                    if mealsHaveARecipe {
                                        Button(action: {
                                            onPinnedToggled(!isPinned)
                                        }) {
                                            Label(
                                                isPinned ? "Unpin" : "Pin",
                                                systemImage: isPinned ? "pin.slash" : "pin")
                                        }
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
                .background {
                    ZStack {
                        // Base background color
                        isSelectedForSwap
                            ? Colours.backgroundSecondary
                            : Colours.backgroundSecondary.opacity(0.5)

                        // Dish photo overlay
                        if !showAvailability,
                            let recipe = firstRecipe,
                            let dishPhotoData = recipe.dishPhotoData,
                            let uiImage = UIImage(data: dishPhotoData)
                        {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .opacity(0.2)
                        }
                    }
                }
                .cornerRadius(8)
                .overlay(
                    isSelectedForSwap
                        ? RoundedRectangle(cornerRadius: 8)
                            .stroke(Colours.foregroundPrimary, lineWidth: 2)
                        : nil
                )

                // Pin indicator
                if isPinned && mealsHaveARecipe {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(Colours.foregroundPrimary)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showRecipeDetails) {
            if let recipe = firstRecipe {
                RecipeDetailsDisplayView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showMealChoice) {
            if let recipe = firstRecipe {
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
                onCreateRecipe: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onCreateRecipe()
                    }
                }
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

    private func areRecipesDifferent(_ selectedPeople: [Person]) -> Bool {
        guard selectedPeople.count > 1 else { return false }

        let selectedMeals = meals.filter { selectedPeople.contains($0.person) }
        let recipeNames = selectedMeals.map { $0.recipe?.name ?? "Choose a meal" }
        let normalizedNames = Set(recipeNames)

        // Check if there's more than one distinct recipe (excluding multiple "Choose a meal" entries)
        return normalizedNames.count > 1
    }
}
