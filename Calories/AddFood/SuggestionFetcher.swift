//
//  SuggestionFetcher.swift
//  Calories
//
//  Created by Tony Short on 03/09/2024.
//

import Foundation
import SwiftData

struct SuggestionFetcher {
    let modelContext: ModelContext
    let excludedSuggestions: [String]

    func fetchSuggestions(searchText: String = "") -> [String] {
        guard searchText.count > 1 else { return [] }
        let predicate = #Predicate<PlantEntry> { $0.name.localizedStandardContains(searchText) && !excludedSuggestions.contains($0.name) }
        return modelContext.plantResults(for: predicate, sortBy: [SortDescriptor(\.name)]).map { $0.name }
    }
}
