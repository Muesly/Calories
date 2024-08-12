//
//  MealBreakdownView.swift
//  Calories
//
//  Created by Tony Short on 05/03/2023.
//

import SwiftUI

struct MealBreakdownView: View {
    var viewModel: MealBreakdownViewModel

    init(viewModel: MealBreakdownViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Meal breakdown")
            Canvas { context, size in
                let slices = viewModel.caloriesPerMealType
                let total = slices.reduce(0) { $0 + $1.0 }
                context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
                var pieContext = context
                pieContext.rotate(by: .degrees(-90))
                let radius = min(size.width, size.height) * 0.48
                var startAngle = Angle.zero
                for (value, color) in slices {
                    let angle = Angle(degrees: 360 * (value / total))
                    let endAngle = startAngle + angle
                    let path = Path { p in
                        p.move(to: .zero)
                        p.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                        p.closeSubpath()
                    }
                    pieContext.fill(path, with: .color(color))

                    startAngle = endAngle
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .padding(EdgeInsets(top: 0, leading: 80, bottom: 0, trailing: 80))
        .onAppear {
            Task {
                await viewModel.getCaloriesPerMealType()
                print(viewModel.caloriesPerMealType)
            }
        }
    }
}
