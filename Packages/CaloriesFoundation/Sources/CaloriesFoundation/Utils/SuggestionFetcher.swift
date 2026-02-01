//
//  SuggestionFetcher.swift
//  Calories
//
//  Created by Tony Short on 03/09/2024.
//

import Foundation
import SwiftData

public struct SuggestionFetcher {
    let modelContext: ModelContext
    let excludedSuggestions: [String]

    public init(modelContext: ModelContext, excludedSuggestions: [String] = []) {
        self.modelContext = modelContext
        self.excludedSuggestions = excludedSuggestions
    }

    public func fetchSuggestions(searchText: String?) -> [String] {
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
