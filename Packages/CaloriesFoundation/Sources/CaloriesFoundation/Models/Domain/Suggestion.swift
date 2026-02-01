//
//  Suggestion.swift
//  Calories
//
//  Created by Tony Short on 12/08/2024.
//

import Foundation
import SwiftUI

struct Suggestion: Hashable {
    let name: String
    var uiImage: UIImage?
    var calories: Int?
    var isRecipeSuggestion: Bool = false

    init(
        name: String, uiImage: UIImage? = nil, calories: Int? = nil,
        isRecipeSuggestion: Bool = false
    ) {
        self.name = name
        self.uiImage = uiImage
        self.calories = calories
        self.isRecipeSuggestion = isRecipeSuggestion
    }
}
