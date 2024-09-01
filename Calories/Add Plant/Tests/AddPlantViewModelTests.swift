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
    @Test func previousPlantsReturnedAlphabetically() async throws {
        let modelContext = ModelContext.inMemory
        let sut = AddPlantViewModel(modelContext: modelContext)
        let _ = [PlantEntry("Pears"), PlantEntry("Apples")].forEach { $0.insert(into: modelContext) }
        sut.fetchSuggestions()
        #expect(sut.suggestions.map { $0.name } == ["Apples", "Pears"])
    }

}
