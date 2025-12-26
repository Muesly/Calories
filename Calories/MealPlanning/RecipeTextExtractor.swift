//
//  RecipeTextExtractor.swift
//  Calories
//
//  Created by Tony Short on 26/12/2025.
//

import FoundationModels
import NaturalLanguage
import SwiftUI
import Vision

// MARK: - Recipe Text Extractor

struct RecipeTextExtractor {
    static func extractRecipeData(from image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
            guard let observations = request.results,
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
                    let names = foundationModelResults.names
                    return names
                }
            }

            let names = parseRecipeNames(from: extractedText)
            return names
        } catch {
            return []
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
            guard let observations = request.results,
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
                2. Ingredients including quantity and units but keeping them together

                Format your response as:
                RECIPES:
                [recipe name 1]
                [recipe name 2]
                INGREDIENTS:
                [ingredient name]
                [ingredient name]

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
        guard components.count >= 1 else { return nil }

        let ingredientName = components[0]

        return RecipeIngredientCandidate(
            ingredientName: ingredientName
        )
    }

    private static func parseRecipeNames(from text: String) -> [String] {
        let lines = text.split(separator: "\n").map(String.init)

        // Filter out obvious non-recipe lines and create candidates
        let candidates = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces).capitalized
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

            if components.count >= 1 {
                let ingredientName = components[0]
                if !isMetadataLine(ingredientName) {
                    ingredients.append(
                        RecipeIngredientCandidate(
                            ingredientName: ingredientName
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
