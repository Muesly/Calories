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

    func fetchSuggestions(searchText: String?) -> [String] {
        if let searchText {
            guard searchText.count > 1 else { return [] }
        }

        let predicate = #Predicate<IngredientEntry> {
            $0.isPlant
                && !excludedSuggestions.contains($0.name)
                && (searchText == nil || $0.name.localizedStandardContains(searchText!))
        }

        return modelContext.ingredientResults(for: predicate, sortBy: [SortDescriptor(\.name)])
            .map(\.name)
    }
}
