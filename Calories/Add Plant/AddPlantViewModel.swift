//
//  AddPlantViewModel.swift
//  Calories
//
//  Created by Tony Short on 28/08/2024.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class AddPlantViewModel: ObservableObject {
    let modelContext: ModelContext
    let plantImageGenerator: PlantImageGenerating
    var suggestions: [Suggestion] = []

    init(modelContext: ModelContext,
         plantImageGenerator: PlantImageGenerating) {
        self.modelContext = modelContext
        self.plantImageGenerator = plantImageGenerator
    }

    func fetchSuggestions(searchText: String = "") {
        var results = modelContext.plantResults()
        if !searchText.isEmpty { // Show fuzzy matched strings for this search text
            results = results.filter { $0.name.fuzzyMatch(searchText) }
        }
        suggestions = results.sorted(by: { s1, s2 in
            s1.name < s2.name
        }).map { Suggestion(name: $0.name, uiImage: $0.uiImage) }
    }

    func fetchImagesForSuggestion(_ suggestion: Suggestion) async throws {
        let name = suggestion.name
        let uiImageData = try await plantImageGenerator.generate(for: suggestion.name)
        let uiImage = UIImage(data: uiImageData)
        let suggestionWithImage = Suggestion(name: suggestion.name, uiImage: uiImage)

        guard let index = suggestions.firstIndex(of: suggestion),
              index != NSNotFound else {
            return
        }
        suggestions[index] = suggestionWithImage
        guard let foundPlant = modelContext.plantResults(for: #Predicate { $0.name == name }).first else {
            return
        }
        foundPlant.imageData = uiImageData
        modelContext.insert(foundPlant)
        try modelContext.save()
    }
}
