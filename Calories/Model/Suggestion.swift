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

    init(name: String, uiImage: UIImage? = nil) {
        self.name = name
        self.uiImage = uiImage
    }
}
