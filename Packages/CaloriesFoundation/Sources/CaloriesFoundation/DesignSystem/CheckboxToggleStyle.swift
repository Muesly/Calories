//
//  CheckboxToggleStyle.swift
//  Calories
//
//  Created by Tony Short on 07/07/2025.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Colours.foregroundPrimary, lineWidth: 1)
                .frame(width: 20, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(configuration.isOn ? Color.accentColor : Color.clear)
                        .frame(width: 14, height: 14)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
        .contentShape(Rectangle())
    }
}
