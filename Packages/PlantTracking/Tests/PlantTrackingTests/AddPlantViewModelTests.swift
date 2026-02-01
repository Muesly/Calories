//
//  AddPlantViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 31/08/2024.
//

import SwiftData
import Testing

@testable import Calories

struct AddPlantViewModelTests {
    @Test func previousPlantsReturnedAlphabeticallyAndExcludes() async throws {
        let modelContext = ModelContext.inMemory
        let sut = AddPlantViewModel(
            suggestionFetcher: SuggestionFetcher(
                modelContext: modelContext, excludedSuggestions: ["Oranges"]))
        let _ = [
            IngredientEntry("Pears", isPlant: true),
            IngredientEntry("Apples", isPlant: true),
            IngredientEntry("Oranges", isPlant: true),
        ].forEach {
            $0.insert(into: modelContext)
        }
        sut.fetchSuggestions()
        #expect(sut.suggestions.map { $0.name } == ["Apples", "Pears"])
    }
}
