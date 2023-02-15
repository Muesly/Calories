//
//  Theme.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import SwiftUI

enum Colours {
    static let backgroundPrimary = Color("backgroundPrimary")
    static let backgroundSecondary = Color("backgroundSecondary")
}

extension Font {
    static var brand = Font
        .custom("Avenir Next", size: UIFont.preferredFont(
            forTextStyle: .body
        ).pointSize)
}
