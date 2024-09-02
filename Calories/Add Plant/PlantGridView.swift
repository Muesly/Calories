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
    GridItem(.fixed(130), spacing: 0),
    GridItem(.fixed(130), spacing: 0),
    GridItem(.fixed(130), spacing: 0)
]

struct PlantGridView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var plantImageGenerator: PlantImageGenerating
    @State var plantSelections: [PlantSelection]
    @State var added: ((String) -> Void)

    init(plantSelections: [PlantSelection], added: @escaping (String) -> Void) {
        self.plantSelections = plantSelections
        self.added = added
        let openAIAPIKey = Bundle.main.infoDictionary!["GPT API Key"]! as! String
        plantImageGenerator = PlantImageGenerator(apiKey: openAIAPIKey)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(plantSelections, id: \.name) { plantSelection in
                let viewModel = PlantCellViewModel(
                    plantSelection: plantSelection,
                    plantImageGenerator: plantImageGenerator,
                    modelContext: modelContext)
                PlantCellView(viewModel: viewModel,
                          added: {

                    added(plantSelection.name)
                })
            }
        }
    }
}

#Preview {
    let modelContext = ModelContext.inMemory
    let _ = [PlantEntry("Corn", imageData: UIImage(named: "Corn")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Rice", imageData: UIImage(named: "Rice")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Broccoli", imageData: UIImage(named: "Broccoli")?.jpegData(compressionQuality: 0.9)),
             PlantEntry("Unidentified"),
             PlantEntry("Corn 2", imageData: UIImage(named: "Corn")?.jpegData(compressionQuality: 0.9))].forEach { modelContext.insert($0)
    }
    VStack {
        PlantGridView(plantSelections: ["Corn", "Rice", "Broccoli", "Unidentified", "Corn 2"].map { PlantSelection($0) }, added: { _ in })

        PlantGridView(plantSelections: [PlantSelection("Corn", isSelected: true)], added: { _ in })
    }
    .modelContext(modelContext)
}
