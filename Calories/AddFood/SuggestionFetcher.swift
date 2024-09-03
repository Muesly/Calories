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
        var results = modelContext.plantResults()
        if !searchText.isEmpty { // Show fuzzy matched strings for this search text
            results = results.filter { $0.name.fuzzyMatch(searchText) }
        }
        return results.filter { !excludedSuggestions.contains($0.name) }.sorted(by: { s1, s2 in
            s1.name < s2.name
        }).map { $0.name }
    }
}
