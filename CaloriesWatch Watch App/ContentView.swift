//
//  ContentView.swift
//  CaloriesWatch Watch App
//
//  Created by Tony Short on 15/02/2023.
//

import Charts
import SwiftUI

struct ContentView: View {
    let viewModel: ContentViewModel

    @State var daysCaloriesData: [CalorieDataPointsType] = []
    @State var weeklyProgress: Double = 0

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Chart {
                ForEach(daysCaloriesData) { dayCalorieData in
                    ForEach(dayCalorieData.dataPoints) {
                        BarMark(x: .value("Day", $0.weekdayStr), y: .value("Calories", $0.calories))
                            .foregroundStyle($0.barColour)
                    }
                    .position(by: .value("Day", dayCalorieData.barType))
                }
                RuleMark(
                    xStart: .value("Day", daysCaloriesData.first?.dataPoints.first?.weekdayStr ?? ""),
                    xEnd: .value("Day", daysCaloriesData.first?.dataPoints.last?.weekdayStr ?? ""),
                    y: .value("Calories", -500)
                ).lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .padding()
        .task {
            (daysCaloriesData, weeklyProgress) = await viewModel.getDaysCalorieData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel())
    }
}
