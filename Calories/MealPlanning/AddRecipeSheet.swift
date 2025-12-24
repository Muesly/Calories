//
//  AddRecipeSheet.swift
//  Calories
//
//  Created by Tony Short on 23/12/2025.
//

import FoundationModels
import NaturalLanguage
import SwiftData
import SwiftUI
import Vision
import VisionKit

struct AddRecipeSheet: View {
    @Binding var isPresented: Bool
    let modelContext: ModelContext
    @State private var recipeName = ""
    @State private var breakfastSuitability: MealSuitability = .never
    @State private var lunchSuitability: MealSuitability = .never
    @State private var dinnerSuitability: MealSuitability = .never
    @State private var dishPhoto: UIImage? = nil
    @State private var stepsPhoto: UIImage? = nil
    @State private var showDishCamera = false
    @State private var showStepsCamera = false
    @State private var showCameraSheet = false
    @State private var showNameDropdown = false
    @State private var fullScreenPhoto: UIImage? = nil
    @State private var showFullScreenPhoto = false
    @State private var photoZoomScale: CGFloat = 1.0
    @State private var photoOffset: CGSize = .zero
    @State private var extractedRecipeNameCandidates: [String] = []
    @State private var extractedIngredientCandidates: [RecipeIngredientCandidate] = []
    @State private var recipeIngredients: [RecipeIngredientCandidate] = []

    var isFormValid: Bool {
        let hasName = !recipeName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAtLeastOneSuitability =
            breakfastSuitability != .never || lunchSuitability != .never
            || dinnerSuitability != .never
        return hasName && hasAtLeastOneSuitability
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Button(action: {
                        showDishCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.on.rectangle")
                            Text("Dish")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Colours.backgroundSecondary)
                        .foregroundColor(Colours.foregroundPrimary)
                        .cornerRadius(8)
                    }

                    Button(action: {
                        showStepsCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.on.rectangle")
                            Text("Steps")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Colours.backgroundSecondary)
                        .foregroundColor(Colours.foregroundPrimary)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if dishPhoto != nil || stepsPhoto != nil {
                    HStack(spacing: 12) {
                        if let dishPhoto {
                            Button(action: {
                                fullScreenPhoto = dishPhoto
                                showFullScreenPhoto = true
                            }) {
                                Image(uiImage: dishPhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        if let stepsPhoto {
                            Button(action: {
                                fullScreenPhoto = stepsPhoto
                                showFullScreenPhoto = true
                            }) {
                                Image(uiImage: stepsPhoto)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    if stepsPhoto != nil {
                        scanRecipe(from: stepsPhoto!)
                    } else {
                        showCameraSheet = true
                    }
                }) {
                    Text("Scan recipe")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Colours.backgroundSecondary)
                        .foregroundColor(Colours.foregroundPrimary)
                        .cornerRadius(8)
                }

                Form {
                    Section(header: Text("Recipe Name")) {
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Enter recipe name", text: $recipeName)
                                if !extractedRecipeNameCandidates.isEmpty {
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
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(Colours.foregroundPrimary)
                                    }
                                }
                            }
                        }
                    }

                    SuitabilitySection(title: "Breakfast", selection: $breakfastSuitability)
                    SuitabilitySection(title: "Lunch", selection: $lunchSuitability)
                    SuitabilitySection(title: "Dinner", selection: $dinnerSuitability)

                    if !recipeIngredients.isEmpty {
                        Section(header: Text("Ingredients")) {
                            ForEach(recipeIngredients, id: \.id) { ingredient in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ingredient.ingredientName)
                                            .font(.body)
                                            .foregroundColor(Colours.foregroundPrimary)
                                        Text(ingredient.displayString)
                                            .font(.caption)
                                            .foregroundColor(Colours.foregroundPrimary.opacity(0.7))
                                    }
                                    Spacer()
                                }
                            }
                            .onDelete(perform: deleteIngredients)
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
                            var recipeIngredientsForSave: [RecipeIngredient] = []
                            for ingredient in recipeIngredients {
                                let ingredientEntry =
                                    modelContext.findIngredient(
                                        ingredient.ingredientName, isPlant: false)
                                    ?? IngredientEntry(ingredient.ingredientName, isPlant: false)
                                let recipeIngredient = RecipeIngredient(
                                    quantity: ingredient.quantity,
                                    unit: ingredient.unit,
                                    ingredient: ingredientEntry
                                )
                                recipeIngredientsForSave.append(recipeIngredient)
                                modelContext.insert(ingredientEntry)
                                modelContext.insert(recipeIngredient)
                            }

                            let newRecipe = RecipeEntry(
                                name: recipeName,
                                breakfastSuitability: breakfastSuitability,
                                lunchSuitability: lunchSuitability,
                                dinnerSuitability: dinnerSuitability,
                                recipeIngredients: recipeIngredientsForSave
                            )
                            modelContext.insert(newRecipe)
                            try? modelContext.save()
                            isPresented = false
                        }
                        .foregroundColor(Colours.foregroundPrimary)
                        .disabled(!isFormValid)
                    }
                }
                .sheet(isPresented: $showCameraSheet) {
                    CameraViewControllerRepresentable { image in
                        scanRecipe(from: image)
                    }
                }
                .sheet(isPresented: $showDishCamera) {
                    ImagePickerView(image: $dishPhoto, isPresented: $showDishCamera)
                }
                .sheet(isPresented: $showStepsCamera) {
                    ImagePickerView(image: $stepsPhoto, isPresented: $showStepsCamera)
                }
                .fullScreenCover(isPresented: $showFullScreenPhoto) {
                    ZStack {
                        Color.black.ignoresSafeArea()

                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    photoZoomScale = 1.0
                                    photoOffset = .zero
                                    showFullScreenPhoto = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            }

                            Spacer()

                            if let photo = fullScreenPhoto {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(photoZoomScale)
                                    .offset(photoOffset)
                                    .gesture(
                                        SimultaneousGesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    photoZoomScale = max(1.0, value)
                                                },
                                            DragGesture()
                                                .onChanged { value in
                                                    photoOffset = value.translation
                                                }
                                        )
                                    )
                                    .onTapGesture(count: 2) {
                                        withAnimation {
                                            if photoZoomScale > 1.5 {
                                                photoZoomScale = 1.0
                                                photoOffset = .zero
                                            } else {
                                                photoZoomScale = 2.5
                                            }
                                        }
                                    }
                                    .padding()
                            }

                            Spacer()
                        }
                    }
                    .onChange(of: showFullScreenPhoto) { oldValue, newValue in
                        if !newValue {
                            photoZoomScale = 1.0
                            photoOffset = .zero
                        }
                    }
                }
            }
        }
    }

    private func scanRecipe(from image: UIImage) {
        Task {
            let (recipeNames, ingredients) = await RecipeTextExtractor.extractRecipeData(
                from: image)

            if !recipeNames.isEmpty || !ingredients.isEmpty {
                // Small delay to ensure camera sheet closes
                try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

                await MainActor.run {
                    extractedRecipeNameCandidates = recipeNames
                    extractedIngredientCandidates = ingredients
                    recipeIngredients = ingredients
                    if !recipeNames.isEmpty {
                        recipeName = recipeNames[0]
                    }
                }
            }
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        recipeIngredients.remove(atOffsets: offsets)
    }
}

// MARK: - Recipe Ingredient Candidate

struct RecipeIngredientCandidate: Identifiable {
    let id = UUID()
    let ingredientName: String
    let quantity: Double
    let unit: IngredientUnit

    var displayString: String {
        let quantityStr = String(format: "%.2g", quantity).replacingOccurrences(of: ",", with: ".")
        return "\(quantityStr) \(unit.displayName)"
    }
}

// MARK: - Suitability Section

private struct SuitabilitySection: View {
    let title: String
    @Binding var selection: MealSuitability

    var body: some View {
        Section(header: Text(title)) {
            Picker("\(title) Suitability", selection: $selection) {
                Text("Never").tag(MealSuitability.never)
                Text("Sometimes").tag(MealSuitability.some)
                Text("Always").tag(MealSuitability.always)
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Image Picker View

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, isPresented: $isPresented)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var image: UIImage?
        @Binding var isPresented: Bool

        init(image: Binding<UIImage?>, isPresented: Binding<Bool>) {
            _image = image
            _isPresented = isPresented
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                image = uiImage
            }
            isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isPresented = false
        }
    }
}

// MARK: - Camera View Controller

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let onImageCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCapture: onImageCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImageCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImageCapture = onImageCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Recipe Text Extractor

struct RecipeTextExtractor {
    static func extractRecipeData(from image: UIImage) async -> (
        names: [String], ingredients: [RecipeIngredientCandidate]
    ) {
        guard let cgImage = image.cgImage else { return ([], []) }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
            guard let observations = request.results as? [VNRecognizedTextObservation],
                !observations.isEmpty
            else {
                return ([], [])
            }

            let extractedText =
                observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            // Try Foundation Model first, fall back to heuristic scoring
            if #available(iOS 26.0, *) {
                if let foundationModelResults = await extractUsingFoundationModel(extractedText) {
                    let names = foundationModelResults.names
                    let ingredients = foundationModelResults.ingredients
                    return (names, ingredients)
                }
            }

            let names = parseRecipeNames(from: extractedText)
            let ingredients = parseIngredients(from: extractedText)
            return (names, ingredients)
        } catch {
            return ([], [])
        }
    }

    static func extractRecipeNames(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
            guard let observations = request.results as? [VNRecognizedTextObservation],
                !observations.isEmpty
            else {
                return []
            }

            let extractedText =
                observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            // Try Foundation Model first, fall back to heuristic scoring
            if #available(iOS 26.0, *) {
                if let foundationModelResults = await extractUsingFoundationModel(extractedText) {
                    return foundationModelResults.names
                }
            }

            return parseRecipeNames(from: extractedText)
        } catch {
            return []
        }
    }

    @available(iOS 26.0, *)
    private static func extractUsingFoundationModel(_ text: String) async -> (
        names: [String], ingredients: [RecipeIngredientCandidate]
    )? {
        guard SystemLanguageModel.default.availability == .available else { return nil }

        do {
            let session = LanguageModelSession()

            let prompt = """
                Analyze this text extracted from a recipe book page. Extract:
                1. Recipe names (1-2 most likely)
                2. Ingredients with quantities and units

                Format your response as:
                RECIPES:
                [recipe name 1]
                [recipe name 2]
                INGREDIENTS:
                [quantity] [unit] [ingredient name]
                [quantity] [unit] [ingredient name]

                Text:
                \(text)
                """

            let response = try await session.respond(to: prompt)
            let lines = response.content.split(separator: "\n").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            var names: [String] = []
            var ingredients: [RecipeIngredientCandidate] = []
            var currentSection = ""

            for line in lines {
                if line.hasPrefix("RECIPES:") {
                    currentSection = "recipes"
                } else if line.hasPrefix("INGREDIENTS:") {
                    currentSection = "ingredients"
                } else if !line.isEmpty {
                    if currentSection == "recipes" {
                        names.append(line)
                    } else if currentSection == "ingredients" {
                        if let ingredient = parseIngredientLine(line) {
                            ingredients.append(ingredient)
                        }
                    }
                }
            }

            return (names, ingredients)
        } catch {
            return nil
        }
    }

    private static func parseIngredientLine(_ line: String) -> RecipeIngredientCandidate? {
        let components = line.split(separator: " ", maxSplits: 2).map(String.init)
        guard components.count >= 3 else { return nil }

        guard let quantity = Double(components[0]) else { return nil }
        let unitStr = components[1]
        let ingredientName = components[2]

        guard let unit = IngredientUnit(rawValue: unitStr) else { return nil }

        return RecipeIngredientCandidate(
            ingredientName: ingredientName,
            quantity: quantity,
            unit: unit
        )
    }

    private static func parseRecipeNames(from text: String) -> [String] {
        let lines = text.split(separator: "\n").map(String.init)

        // Filter out obvious non-recipe lines and create candidates
        let candidates = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && trimmed.count >= 3 && !isMetadataLine(trimmed)
        }

        // Score and sort candidates using linguistic analysis
        let scoredCandidates = candidates.map { candidate -> (name: String, score: Double) in
            let trimmed = candidate.trimmingCharacters(in: .whitespaces)
            let score = scoreRecipeName(trimmed)
            return (trimmed, score)
        }
        .sorted { $0.score > $1.score }  // Sort by score descending
        .map { $0.name }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        return scoredCandidates.filter { candidate in
            let isNew = !seen.contains(candidate)
            seen.insert(candidate)
            return isNew
        }
    }

    private static func parseIngredients(from text: String) -> [RecipeIngredientCandidate] {
        let lines = text.split(separator: "\n").map(String.init)
        var ingredients: [RecipeIngredientCandidate] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Look for lines with pattern: number unit ingredient
            let components = trimmed.split(separator: " ", maxSplits: 2).map(String.init)

            if components.count >= 3,
                let quantity = Double(components[0]),
                let unit = IngredientUnit(rawValue: components[1])
            {
                let ingredientName = components[2]
                if !isMetadataLine(ingredientName) {
                    ingredients.append(
                        RecipeIngredientCandidate(
                            ingredientName: ingredientName,
                            quantity: quantity,
                            unit: unit
                        ))
                }
            }
        }

        return ingredients
    }

    private static func scoreRecipeName(_ text: String) -> Double {
        let analysis = analyzeLinguisticFeatures(text)
        var score = 0.0

        // Base score for having nouns with reasonable word count
        if analysis.hasNoun && analysis.wordCount >= 2 && analysis.wordCount <= 8 {
            score += 3.0
        }

        // Reward multiple nouns (typical in recipe names)
        score += Double(analysis.nounCount) * 0.5

        // Reward adjectives (e.g., "Spicy Chicken Soup")
        score += Double(analysis.adjectiveCount) * 0.3

        // Reward capitalization pattern (recipe names are usually title-cased)
        if analysis.capitalizationRatio >= 0.5 {
            score += 1.5
        }

        // Penalize very long names (metadata often gets extracted as long strings)
        if analysis.wordCount > 8 {
            score -= Double(analysis.wordCount - 8) * 0.2
        }

        // Reward moderate length (2-5 words is typical for recipe names)
        if analysis.wordCount >= 2 && analysis.wordCount <= 5 {
            score += 1.0
        }

        // Penalize names with numbers (likely page numbers or nutrition info)
        if text.contains(where: { $0.isNumber }) {
            score -= 1.0
        }

        return max(score, 0.0)
    }

    private struct LinguisticAnalysis {
        let wordCount: Int
        let nounCount: Int
        let adjectiveCount: Int
        let capitalizationRatio: Double
        var hasNoun: Bool { nounCount > 0 }
    }

    private static func analyzeLinguisticFeatures(_ text: String) -> LinguisticAnalysis {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var nounCount = 0
        var adjectiveCount = 0
        var wordCount = 0

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: []
        ) { tag, _ in
            wordCount += 1
            if tag == .noun {
                nounCount += 1
            } else if tag == .adjective {
                adjectiveCount += 1
            }
            return true
        }

        let words = text.split(separator: " ")
        let capitalizedCount = words.filter { $0.first?.isUppercase == true }.count
        let capitalizationRatio =
            words.isEmpty ? 0.0 : Double(capitalizedCount) / Double(words.count)

        return LinguisticAnalysis(
            wordCount: wordCount,
            nounCount: nounCount,
            adjectiveCount: adjectiveCount,
            capitalizationRatio: capitalizationRatio
        )
    }

    private static let metadataKeywords = [
        "ingredients", "directions", "instructions", "serves", "time",
    ]

    private static let metadataContains = [
        "mins", "minutes", "makes",
    ]

    private static func isMetadataLine(_ text: String) -> Bool {
        let lower = text.lowercased()
        return metadataKeywords.contains { lower.hasPrefix($0) }
            || metadataContains.contains { lower.contains($0) }
    }
}
