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
    @State private var showCameraSheet = false
    @State private var showRecipeSelection = false
    @State private var extractedCandidates: [String] = []

    var isFormValid: Bool {
        let hasName = !recipeName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAtLeastOneSuitability =
            breakfastSuitability != .never || lunchSuitability != .never
            || dinnerSuitability != .never
        return hasName && hasAtLeastOneSuitability
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recipe Name")) {
                    HStack {
                        TextField("Enter recipe name", text: $recipeName)
                        Button(action: {
                            showCameraSheet = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(Colours.foregroundPrimary)
                        }
                    }
                }

                SuitabilitySection(title: "Breakfast", selection: $breakfastSuitability)
                SuitabilitySection(title: "Lunch", selection: $lunchSuitability)
                SuitabilitySection(title: "Dinner", selection: $dinnerSuitability)
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
                        let newRecipe = RecipeEntry(
                            name: recipeName,
                            breakfastSuitability: breakfastSuitability,
                            lunchSuitability: lunchSuitability,
                            dinnerSuitability: dinnerSuitability
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
                    extractRecipeName(from: image)
                }
            }
            .sheet(isPresented: $showRecipeSelection) {
                NavigationStack {
                    List(extractedCandidates, id: \.self) { candidate in
                        Button(action: {
                            recipeName = candidate
                            showRecipeSelection = false
                        }) {
                            Text(candidate)
                                .foregroundColor(Colours.foregroundPrimary)
                        }
                    }
                    .navigationTitle("Select Recipe")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cancel") {
                                showRecipeSelection = false
                            }
                            .foregroundColor(Colours.foregroundPrimary)
                        }
                    }
                }
            }
        }
    }

    private func extractRecipeName(from image: UIImage) {
        Task {
            let candidates = await RecipeTextExtractor.extractRecipeNames(from: image)
            if !candidates.isEmpty {
                // Small delay to ensure camera sheet closes before recipe selection opens
                try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

                await MainActor.run {
                    extractedCandidates = candidates
                    showRecipeSelection = true
                }
            }
        }
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
                    return foundationModelResults
                }
            }

            return parseRecipeNames(from: extractedText)
        } catch {
            return []
        }
    }

    @available(iOS 26.0, *)
    private static func extractUsingFoundationModel(_ text: String) async -> [String]? {
        guard SystemLanguageModel.default.availability == .available else { return nil }

        do {
            let session = LanguageModelSession()

            let prompt = """
                Analyze this text extracted from a recipe book page and identify the recipe name.
                Return ONLY the recipe name, nothing else. If you find multiple possible recipe names,
                return them separated by newlines, with the most likely one first.

                Text:
                \(text)
                """

            let response = try await session.respond(to: prompt)
            let names = response.content
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            return names.isEmpty ? nil : names
        } catch {
            return nil
        }
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
