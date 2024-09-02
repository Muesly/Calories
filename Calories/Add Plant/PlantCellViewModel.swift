//
//  PlantCellViewModel.swift
//  Calories
//
//  Created by Tony Short on 01/09/2024.
//

import Foundation
import SwiftData
import UIKit

@Observable
class PlantCellViewModel {
    let plant: String
    let plantImageGenerator: PlantImageGenerating
    let modelContext: ModelContext
    var uiImage: UIImage?

    init(plant: String,
         plantImageGenerator: PlantImageGenerating,
         modelContext: ModelContext) {
        self.plant = plant
        self.plantImageGenerator = plantImageGenerator
        self.modelContext = modelContext

        self.uiImage = imageForPlant(plant)
    }

    private func imageForPlant(_ plant: String) -> UIImage? {
        let plantEntry = modelContext.findPlant(plant)
        return plantEntry?.uiImage
    }

    func fetchImagesForSuggestion() async throws {
        let uiImageData = try await plantImageGenerator.generate(for: plant)
        self.uiImage = UIImage(data: uiImageData)

        guard let foundPlant = modelContext.findPlant(plant) else {
            return
        }
        foundPlant.imageData = uiImageData
        modelContext.insert(foundPlant)
    }
}
