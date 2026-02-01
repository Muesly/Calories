//
//  DisplayConfettiModifier.swift
//  Calories
//
//  Created by Tony Short on 04/08/2024.
//

import SwiftUI
import CaloriesFoundation

struct ConfettiView: View {
    @State var animate = false
    @State var xSpeed = Double.random(in: 0.7...2)
    @State var zSpeed = Double.random(in: 1...2)
    @State var anchor = CGFloat.random(in: 0...1).rounded()

    var body: some View {
        Rectangle()
            .fill(
                [Color.orange, Color.green, Color.blue, Color.red, Color.yellow].randomElement()
                    ?? Color.green
            )
            .frame(width: 20, height: 20)
            .onAppear(perform: { animate = true })
            .rotation3DEffect(.degrees(animate ? 360 : 0), axis: (x: 1, y: 0, z: 0))
            .animation(
                Animation.linear(duration: xSpeed).repeatForever(autoreverses: false),
                value: animate
            )
            .rotation3DEffect(
                .degrees(animate ? 360 : 0), axis: (x: 0, y: 0, z: 1),
                anchor: UnitPoint(x: anchor, y: anchor)
            )
            .animation(
                Animation.linear(duration: zSpeed).repeatForever(autoreverses: false),
                value: animate)
    }
}

struct ConfettiContainerView: View {
    var count: Int = 50
    @State var yPosition: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<count, id: \.self) { _ in
                    ConfettiView()
                        .position(
                            x: CGFloat.random(in: 0...proxy.size.width),
                            y: yPosition != 0
                                ? CGFloat.random(in: 0...proxy.size.height) : yPosition
                        )
                }
            }
            .ignoresSafeArea()
            .onAppear {
                yPosition = CGFloat.random(in: 0...proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct DisplayConfettiModifier: ViewModifier {
    @Binding var isActive: Bool {
        didSet {
            if !isActive {
                opacity = 1
            }
        }
    }
    @State private var opacity = 1.0 {
        didSet {
            if opacity == 0 {
                isActive = false
            }
        }
    }

    private let animationTime = 2.0
    private let fadeTime = 1.5

    func body(content: Content) -> some View {
        content
            .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    Task {
                        await handleAnimationSequence()
                    }
                }
            }
    }

    private func handleAnimationSequence() async {
        do {
            try await Task.sleep(nanoseconds: UInt64(animationTime * 1_000_000_000))
            withAnimation(.easeOut(duration: fadeTime)) {
                opacity = 0
            }
        } catch {}
    }
}

extension View {
    func displayConfetti(isActive: Binding<Bool>) -> some View {
        self.modifier(DisplayConfettiModifier(isActive: isActive))
    }
}
