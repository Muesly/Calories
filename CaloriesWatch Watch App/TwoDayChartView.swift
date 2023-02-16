//
//  TwoDayChartView.swift
//  CaloriesWatch Watch App
//
//  Created by Tony Short on 15/02/2023.
//

import Charts
import SwiftUI

struct TwoDayChartView: View {
    @ObservedObject var viewModel: ContentViewModel

    @State var daysCaloriesData: [CalorieDataPointsType] = []
    @State var weeklyProgress: Double = 0

    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Chart {
                ForEach(viewModel.daysCaloriesData) { dayCalorieData in
                    ForEach(dayCalorieData.dataPoints) {
                        BarMark(x: .value("Day", $0.weekdayStr), y: .value("Calories", $0.calories))
                            .foregroundStyle($0.barColour)
                    }
                    .position(by: .value("Day", dayCalorieData.barType))
                }
                RuleMark(
                    xStart: .value("Day", viewModel.firstDayStr),
                    xEnd: .value("Day", viewModel.lastDayStr),
                    y: .value("Calories", viewModel.deficitGoal)
                ).lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .padding()
        .onAppear {
            refresh()
        }
    }

    private func refresh() {
        Task {
            await viewModel.fetchDaysCalorieData()
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TwoDayChartView(viewModel: ContentViewModel())
    }
}
