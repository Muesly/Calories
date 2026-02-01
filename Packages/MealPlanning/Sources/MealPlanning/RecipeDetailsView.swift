//
//  RecipeDetailsView.swift
//  Calories
//
//  Created by Tony Short on 26/12/2025.
//

import SwiftData
import SwiftUI
import CaloriesFoundation

struct RecipeDetailsView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    let mealType: MealType
    let extractedRecipeNames: [String]
    let onRecipeCreated: (RecipeEntry) -> Void
    @Binding var dishPhoto: UIImage?
    @Binding var stepsPhoto: UIImage?

    @State private var recipeName = ""
    @State private var caloriesPerPortion = ""
    @State private var suggestions = ""
    @State private var selectedBook: BookEntry?
    @State private var pageNumber: Int?
    @State private var rating: Int16 = 0
    @State private var categorySearchText = ""
    @State private var selectedCategories: [CategoryEntry] = []
    @State private var availableCategories: [CategoryEntry] = []
    @State private var breakfastSuitability: MealSuitability = .never
    @State private var lunchSuitability: MealSuitability = .never
    @State private var dinnerSuitability: MealSuitability = .never
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var recipeIngredients: [RecipeIngredientCandidate] = []
    @State private var editingField: String?
    @FocusState private var isCaloriesFocused: Bool

    private var extractedRecipeNameCandidates: [String] {
        extractedRecipeNames
    }

    private var filteredCategories: [CategoryEntry] {
        guard categorySearchText.count >= 2 else {
            return []
        }
        return
            availableCategories
            .filter { $0.name.localizedCaseInsensitiveContains(categorySearchText) }
            .filter { !selectedCategories.contains($0) }
            .sorted { $0.name < $1.name }
    }

    var isFormValid: Bool {
        let hasName = !recipeName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAtLeastOneSuitability =
            breakfastSuitability != .never || lunchSuitability != .never
            || dinnerSuitability != .never
        return hasName && hasAtLeastOneSuitability
    }

    var body: some View {
        VStack(spacing: 16) {
            Form {
                RecipeNameSection(
                    recipeName: $recipeName,
                    extractedRecipeNameCandidates: extractedRecipeNameCandidates
                )
                Section(header: Text("Images")) {
                    HStack(spacing: 12) {
                        RecipeThumbnail(label: "Dish photo", photo: $dishPhoto)
                        RecipeThumbnail(label: "Steps photo", photo: $stepsPhoto)
                    }
                    .frame(height: 200)
                }

                Section(header: Text("Calories per Portion")) {
                    TextField(
                        "Enter calories", text: $caloriesPerPortion,
                        onEditingChanged: { isEditing in
                            self.editingField = isEditing ? "calories" : nil
                        }
                    )
                    .keyboardType(.numberPad)
                    .focused($isCaloriesFocused)
                    .toolbar {
                        if editingField == "calories" {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    editingField = nil
                                    isCaloriesFocused = false
                                }
                            }
                        }
                    }
                }

                RecipeBookSection(
                    modelContext: modelContext,
                    selectedBook: $selectedBook,
                    pageNumber: $pageNumber
                )

                Section(header: Text("Suggestions")) {
                    TextField(
                        "e.g. add more salt, reduce chilli", text: $suggestions, axis: .vertical
                    )
                    .lineLimit(1...2)
                }

                Section(header: Text("Rating")) {
                    RatingView(rating: $rating)
                }

                Section(header: Text("Categories")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("Search or add category", text: $categorySearchText)
                                .autocorrectionDisabled()
                        }

                        if !selectedCategories.isEmpty {
                            WrappedCategories(
                                categories: selectedCategories,
                                onRemove: { category in
                                    selectedCategories.removeAll { $0.name == category.name }
                                }
                            )
                        }

                        if !filteredCategories.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(filteredCategories, id: \.name) { category in
                                    Button(action: {
                                        selectedCategories.append(category)
                                        categorySearchText = ""
                                    }) {
                                        HStack {
                                            Text(category.name)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(Colours.backgroundSecondary)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        if !categorySearchText.isEmpty
                            && !filteredCategories.contains(where: { $0.name == categorySearchText }
                            )
                            && !selectedCategories.contains(where: { $0.name == categorySearchText }
                            )
                        {
                            Button(action: {
                                let newCategory = CategoryEntry(name: categorySearchText)
                                modelContext.insert(newCategory)
                                do {
                                    try modelContext.save()
                                    selectedCategories.append(newCategory)
                                    availableCategories.append(newCategory)
                                    categorySearchText = ""
                                } catch {
                                    print("Error saving new category: \(error)")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create '\(categorySearchText)'")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Colours.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                            }
                        }
                    }
                }

                Section(header: Text("Meal Suitability")) {
                    VStack(spacing: 12) {
                        SuitabilitySection(title: "Breakfast", selection: $breakfastSuitability)
                        SuitabilitySection(title: "Lunch", selection: $lunchSuitability)
                        SuitabilitySection(title: "Dinner", selection: $dinnerSuitability)
                    }
                }
            }
        }
        .navigationTitle("Add Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(Colours.foregroundPrimary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveRecipe()
                }
                .foregroundColor(Colours.foregroundPrimary)
            }
        }
        .alert("Failed to Save Recipe", isPresented: $showSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
        .onAppear {
            if !extractedRecipeNames.isEmpty {
                recipeName = extractedRecipeNames[0]
            }

            // Set default suitability based on meal type
            switch mealType {
            case .breakfast:
                breakfastSuitability = .always
            case .lunch:
                lunchSuitability = .always
            case .dinner:
                dinnerSuitability = .always
            default:
                break
            }

            // Fetch existing categories
            do {
                let descriptor = FetchDescriptor<CategoryEntry>(sortBy: [SortDescriptor(\.name)])
                availableCategories = try modelContext.fetch(descriptor)
            } catch {
                print("Error fetching categories: \(error)")
            }
        }
    }

    private func saveRecipe() {
        guard isFormValid else {
            saveErrorMessage = "Please ensure all required fields are entered"
            showSaveError = true
            return
        }

        do {
            let dishPhotoData = dishPhoto?.jpegData(compressionQuality: 0.8)
            let stepsPhotoData = stepsPhoto?.jpegData(compressionQuality: 0.8)
            let calories = Int(caloriesPerPortion) ?? 0
            let page = pageNumber
            let newRecipe = RecipeEntry(
                name: recipeName,
                breakfastSuitability: breakfastSuitability,
                lunchSuitability: lunchSuitability,
                dinnerSuitability: dinnerSuitability,
                dishPhotoData: dishPhotoData,
                stepsPhotoData: stepsPhotoData,
                caloriesPerPortion: calories,
                suggestions: suggestions,
                book: selectedBook,
                pageNumber: page,
                rating: rating,
                categories: selectedCategories
            )
            modelContext.insert(newRecipe)
            try modelContext.save()
            print("✓ Recipe saved successfully: \(recipeName)")
            isPresented = false
            onRecipeCreated(newRecipe)
        } catch {
            print("✗ Error saving recipe: \(error)")
            if error.localizedDescription.contains("UNIQUE constraint failed")
                || error.localizedDescription.contains("duplicate")
            {
                saveErrorMessage = "A recipe with the name '\(recipeName)' already exists"
            } else {
                saveErrorMessage = "Failed to save recipe: \(error.localizedDescription)"
            }
            showSaveError = true
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        recipeIngredients.remove(atOffsets: offsets)
    }
}

struct RecipeNameSection: View {
    @Binding var recipeName: String
    let extractedRecipeNameCandidates: [String]

    var body: some View {
        Section(header: Text("Recipe Name")) {
            VStack(spacing: 12) {
                HStack {
                    TextField("Enter recipe name", text: $recipeName)
                    // Show a menu of other extracted names if more than one option
                    let numCandidates = extractedRecipeNameCandidates.count
                    if numCandidates > 1 {
                        Menu {
                            ForEach(extractedRecipeNameCandidates, id: \.self) {
                                candidate in
                                Button(action: {
                                    recipeName = candidate
                                }) {
                                    Text(candidate)
                                }
                            }
                        } label: {
                            Text("\(numCandidates) candidates")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
}

struct RecipeBookSection: View {
    let modelContext: ModelContext
    @Binding var selectedBook: BookEntry?
    @Binding var pageNumber: Int?
    @State private var bookSearchText = ""
    @State private var availableBooks: [BookEntry] = []
    @State private var editingPageNumber = false
    @FocusState private var isPageNumberFieldFocued: Bool

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    var body: some View {
        if let selectedBook = selectedBook {
            Section(header: Text("Recipe Book")) {
                HStack {
                    Text(selectedBook.name)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        self.selectedBook = nil
                        bookSearchText = ""
                        pageNumber = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Colours.backgroundSecondary)
                .cornerRadius(8)

                TextField(
                    "Page number", value: $pageNumber, formatter: formatter,
                    onEditingChanged: { isEditing in
                        self.editingPageNumber = isEditing
                    }
                )
                .keyboardType(.numberPad)
                .focused($isPageNumberFieldFocued)
                .toolbar {
                    if editingPageNumber {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                editingPageNumber = false
                                isPageNumberFieldFocued = false
                            }
                        }
                    }
                }
            }
        } else {
            Section(header: Text("Recipe Book")) {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Search or add book", text: $bookSearchText)
                    }

                    if !filteredBooks.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(filteredBooks, id: \.name) { book in
                                Button(action: {
                                    selectedBook = book
                                    bookSearchText = ""
                                }) {
                                    HStack {
                                        Text(book.name)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(8)
                                    .background(Colours.backgroundSecondary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    if !bookSearchText.isEmpty
                        && !filteredBooks.contains(where: { $0.name == bookSearchText })
                    {
                        Button(action: {
                            let newBook = BookEntry(name: bookSearchText)
                            modelContext.insert(newBook)
                            do {
                                try modelContext.save()
                                selectedBook = newBook
                                availableBooks.append(newBook)
                                bookSearchText = ""
                            } catch {
                                print("Error saving new book: \(error)")
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create '\(bookSearchText)'")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Colours.backgroundSecondary)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        }
                    }
                }
            }
            .task {
                // Fetch existing books
                do {
                    let descriptor = FetchDescriptor<BookEntry>(sortBy: [SortDescriptor(\.name)])
                    availableBooks = try modelContext.fetch(descriptor)
                } catch {
                    print("Error fetching books: \(error)")
                }
            }
        }
    }

    private var filteredBooks: [BookEntry] {
        guard bookSearchText.count >= 2 else {
            return []
        }
        return
            availableBooks
            .filter { $0.name.localizedCaseInsensitiveContains(bookSearchText) }
            .sorted { $0.name < $1.name }
    }
}

// MARK: - Wrapped Categories

struct WrappedCategories: View {
    let categories: [CategoryEntry]
    let onRemove: (CategoryEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(groupedCategories.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(groupedCategories[rowIndex], id: \.name) { category in
                        CategoryPill(
                            name: category.name,
                            onRemove: {
                                onRemove(category)
                            }
                        )
                    }
                    Spacer()
                }
            }
        }
    }

    private var groupedCategories: [[CategoryEntry]] {
        var rows: [[CategoryEntry]] = [[]]
        for category in categories {
            rows[rows.count - 1].append(category)
            if rows[rows.count - 1].count >= 3 {
                rows.append([])
            }
        }
        if rows.last?.isEmpty == true {
            rows.removeLast()
        }
        return rows
    }
}

// MARK: - Category Pill

struct CategoryPill: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Colours.backgroundSecondary)
        .cornerRadius(16)
    }
}

// MARK: - Recipe Ingredient Candidate

struct RecipeIngredientCandidate: Identifiable {
    let id = UUID()
    let ingredientName: String
}

// MARK: - Suitability Section

struct SuitabilitySection: View {
    let title: String
    @Binding var selection: MealSuitability
    private let mealLabelWidth = 80.0

    var body: some View {
        HStack {
            Text(title)
                .frame(width: mealLabelWidth, alignment: .trailing)
            Picker("", selection: $selection) {
                Text("Never").tag(MealSuitability.never)
                Text("Sometimes").tag(MealSuitability.sometimes)
                Text("Always").tag(MealSuitability.always)
            }.pickerStyle(.segmented)
        }
    }
}

#Preview {
    @Previewable @State var dishPhoto: UIImage? = UIImage(named: "Corn")
    @Previewable @State var stepsPhoto: UIImage? = UIImage(named: "Corn")
    let modelContext = ModelContext.inMemory
    VStack {
        RecipeDetailsView(
            isPresented: .constant(true),
            mealType: .breakfast,
            extractedRecipeNames: ["Muffins", "asdf"],
            onRecipeCreated: { _ in

            },
            dishPhoto: $dishPhoto,
            stepsPhoto: $stepsPhoto)
    }
    .modelContext(modelContext)
}
