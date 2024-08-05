//
//  ScrollingTextView.swift
//  Calories
//
//  Created by Tony Short on 04/08/2024.
//

import SwiftUI

struct RevealingTextView: View {
    @Binding var text: String
    @State var displayedText: String
    @State private var offsetX: CGFloat = 0
    private let duration = 0.3
    private let offset: CGFloat = 90.0
    
    init(text: Binding<String>) {
        _text = text
        self.displayedText = text.wrappedValue
    }
    
    var body: some View {
        ZStack {
            Text(displayedText)
                .offset(x: offsetX)
                .animation(.easeInOut(duration: duration), value: offsetX)
        }
        .clipped()
        .onChange(of: text) { oldValue, newValue in
            withAnimation {
                if newValue > oldValue {
                    offsetX = offset
                } else {
                    offsetX = -offset
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                displayedText = newValue
                offsetX = -offsetX
                withAnimation {
                    offsetX = 0
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var text: String = "Old Text"
    VStack {
        RevealingTextView(text: $text)
            .onTapGesture {
                text = "New Text"
            }
    }
}
