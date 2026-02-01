//
//  Theme.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import SwiftUI

public enum Colours {
    public static let backgroundPrimary = Color("backgroundPrimary")
    public static let backgroundSecondary = Color("backgroundSecondary")
    public static let foregroundPrimary = Color("foregroundPrimary")
    public static let foregroundSecondary = Color("foregroundSecondary")
}

public extension Font {
    static let brand = Font.custom(
        "Avenir Next",
        size: UIFont.preferredFont(forTextStyle: .body).pointSize)
}

public struct ButtonText: ViewModifier {
    public init() {

    }

    public func body(content: Content) -> some View {
        content
            .padding(10)
            .bold()
            .frame(maxWidth: .infinity)
    }
}
