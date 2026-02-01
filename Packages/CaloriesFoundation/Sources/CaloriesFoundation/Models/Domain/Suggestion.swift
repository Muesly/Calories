//
//  Suggestion.swift
//  Calories
//
//  Created by Tony Short on 12/08/2024.
//

import Foundation
import SwiftUI

public struct Suggestion: Hashable {
    public let name: String
    public var uiImage: UIImage?
    public var calories: Int?
    public var isRecipeSuggestion: Bool = false

    public init(
        name: String, uiImage: UIImage? = nil, calories: Int? = nil,
        isRecipeSuggestion: Bool = false
    ) {
        self.name = name
        self.uiImage = uiImage
        self.calories = calories
        self.isRecipeSuggestion = isRecipeSuggestion
    }
}
