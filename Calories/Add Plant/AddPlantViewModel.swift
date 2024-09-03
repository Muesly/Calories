//
//  AddPlantViewModel.swift
//  Calories
//
//  Created by Tony Short on 28/08/2024.
//

import Foundation
import SwiftUI

@Observable
class AddPlantViewModel: ObservableObject {
    private let suggestionFetcher: SuggestionFetcher
    var suggestions: [String] = []

    init(suggestionFetcher: SuggestionFetcher) {
        self.suggestionFetcher = suggestionFetcher
    }

    func fetchSuggestions(searchText: String = "") {
        suggestions = suggestionFetcher.fetchSuggestions(searchText: searchText)
    }
}
