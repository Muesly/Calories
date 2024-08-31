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
    static let foregroundPrimary = Color("foregroundPrimary")
}

extension Font {
    static var brand = Font.custom("Avenir Next",
                                   size: UIFont.preferredFont(forTextStyle: .body).pointSize)
    static var smallHeading = Font.custom("Avenir Next",
                                          size: 10)
}

struct ButtonText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .bold()
            .frame(maxWidth: .infinity)
    }
}
