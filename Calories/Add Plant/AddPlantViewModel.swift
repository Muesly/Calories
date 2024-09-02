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
    var suggestions: [Suggestion] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
}
