//
//  PlantCellViewModelTests.swift
//  Calories
//
//  Created by Tony Short on 02/09/2024.
//

import SwiftData
import Testing
import UIKit

@testable import Calories

@MainActor
struct PlantCellViewModelTests {
    @Test func cellImageToBeSetWithPlantThatHasImage() async throws {
        let modelContext = ModelContext.inMemory
        let plantEntry = IngredientEntry(
            "Rice",
            imageData: UIImage(systemName: "plus")?.pngData(),
            isPlant: true)
        plantEntry.insert(into: modelContext)

        let sut = PlantCellViewModel(
            plantSelection: .init("Rice"),
            plantImageGenerator: StubbedPlantGenerator(),
            modelContext: modelContext)
        #expect(sut.uiImage != nil)
    }

    @Test func cellImageToBeSetWhenImageGeneratedForPlantWithNoImage() async throws {
        let modelContext = ModelContext.inMemory
        let plantEntry = IngredientEntry("Rice", isPlant: true)
        plantEntry.insert(into: modelContext)

        let plantGenerator = StubbedPlantGenerator()
        plantGenerator.returnedData = UIImage(systemName: "plus")!.pngData()!
        let sut = PlantCellViewModel(
            plantSelection: .init("Rice"),
            plantImageGenerator: plantGenerator,
            modelContext: modelContext)
        try await sut.fetchImagesForSuggestion()
        #expect(sut.uiImage != nil)

        let modifiedPlantEntry = modelContext.findPlant("Rice")
        #expect(modifiedPlantEntry?.uiImage != nil)
    }
}
