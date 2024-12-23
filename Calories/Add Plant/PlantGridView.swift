//
//  PlantGrid.swift
//  Calories
//
//  Created by Tony Short on 01/09/2024.
//

import SwiftData
import SwiftUI
import UIKit

let columns = [
    GridItem(.fixed(110), spacing: 0),
    GridItem(.fixed(110), spacing: 0),
    GridItem(.fixed(110), spacing: 0)
]

struct PlantGridView: View {
    @Environment(\.modelContext) private var modelContext
    let plantImageGenerator: PlantImageGenerating
    let plantSelections: [PlantSelection]
    @Binding var addedPlant: String

    init(plantSelections: [PlantSelection], addedPlant: Binding<String>) {
        self.plantSelections = plantSelections
        self._addedPlant = addedPlant
        let openAIAPIKey = Bundle.main.infoDictionary!["GPT API Key"]! as! String
        plantImageGenerator = PlantImageGenerator(apiKey: openAIAPIKey)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(plantSelections, id: \.self) { plantSelection in
                let viewModel = PlantCellViewModel(
                    plantSelection: plantSelection,
                    plantImageGenerator: plantImageGenerator,
                    modelContext: modelContext)
                PlantCellView(viewModel: viewModel,
                              addedPlant: $addedPlant)
            }
        }
    }
}

#Preview {
    let modelContext = ModelContext.inMemory
    let _ = [PlantEntry("Corn", imageName: "Corn"),
             PlantEntry("Rice", imageName: "Rice"),
             PlantEntry("Broccoli", imageName: "Broccoli"),
             PlantEntry("Unidentified"),
             PlantEntry("Corn 2", imageName: "Corn")].forEach { modelContext.insert($0)
    }
    VStack {
        PlantGridView(plantSelections: ["Corn", "Rice", "Broccoli", "Unidentified", "Corn 2"].map { PlantSelection($0) }, addedPlant: .constant(""))

        PlantGridView(plantSelections: [PlantSelection("Corn", isSelected: true)], addedPlant: .constant(""))
    }
    .modelContext(modelContext)
}
