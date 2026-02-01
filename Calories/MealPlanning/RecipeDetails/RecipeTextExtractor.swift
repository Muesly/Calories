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
    struct ExtractionResult {
        let recipeNames: [String]
        let plants: [String]
    }

    static func extractRecipeData(from image: UIImage) async -> ExtractionResult? {
        do {
            guard let extractedText = try extractedText(fromImage: image) else {
                return nil
            }
            let plants = extractPlants(from: extractedText)
            let recipeNames = try await extractRecipeNames(extractedText)
            return ExtractionResult(recipeNames: recipeNames, plants: plants)
        } catch {
            print("Failed to extract recipe information: \(error)")
            return nil
        }
    }

    private static func extractedText(fromImage image: UIImage) throws -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let handler = VNImageRequestHandler(cgImage: cgImage)

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false

        try handler.perform([request])
        guard let observations = request.results, !observations.isEmpty else {
            return nil
        }

        return observations.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    private static func extractRecipeNames(_ text: String) async throws -> [String] {
        guard SystemLanguageModel.default.availability == .available else { return [] }

        let session = LanguageModelSession()

        let prompt = """
            Analyze this text extracted from a recipe book page. Extract:
            1. Recipe names (1-2 most likely recipe titles - look for dish names, not instructions or ingredients)

            Recipe names are typically:
            - 2-6 words long
            - Descriptive of a dish (e.g., "Spicy Thai Curry", "Chocolate Brownies")
            - NOT ingredient lists, instructions, or metadata like page numbers or cooking times

            Format your response as:
            RECIPES:
            [recipe name 1]
            [recipe name 2]

            The recipe text is:
            \(text)
            """

        let response = try await session.respond(to: prompt)
        let lines = response.content.split(separator: "\n").map {
            $0.trimmingCharacters(in: .whitespaces)
        }

        var names: [String] = []
        var currentSection = ""

        for line in lines {
            if line.hasPrefix("RECIPES:") {
                currentSection = "recipes"
            } else if !line.isEmpty {
                if currentSection == "recipes" {
                    names.append(line)
                }
            }
        }
        return names
    }

    static func extractPlants(from text: String) -> [String] {
        let lowercased = text.lowercased()
        var foundPlants = Set<String>()

        // Look for each plant in the text
        for plant in PlantDatabase.plants {
            // Use word boundary matching to avoid partial matches
            let pattern = "\\b\(plant)s?\\b"  // Match singular or plural
            if let _ = lowercased.range(of: pattern, options: .regularExpression) {
                // Normalize to singular form for consistency
                let normalized = plant.hasSuffix("s") ? plant : plant
                foundPlants.insert(normalized.capitalized)
            }
        }

        return Array(foundPlants).sorted()
    }
}
