//
//  WeeklyChartView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Charts
import SwiftUI

struct WeeklyChartView: View {
    var viewModel: WeeklyChartViewModel

    var body: some View {
        VStack(spacing: 20) {
            DaysCaloriesChart(viewModel: viewModel)
            WeeklyProgressChart(viewModel: viewModel)
        }
        .font(.brand)
    }
}

struct DaysCaloriesChart: View {
    let viewModel: WeeklyChartViewModel

    var body: some View {
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
        .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
        .frame(height: 200)
        .chartForegroundStyleScale(["Burnt": .blue, "Consumed": .cyan, "Good": .green, "Ok": .orange, "Bad": .red])
    }
}

struct WeeklyProgressChart: View {
    let viewModel: WeeklyChartViewModel

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        viewModel.previousWeekPressed()
                    } label: {
                        Image(systemName: "arrowshape.backward.fill")
                    }
                    .disabled(!viewModel.previousWeekEnabled)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                    Text("Progress from \(viewModel.startOfWeek)")
                        .frame(maxWidth: .infinity)
                    Button {
                        viewModel.nextWeekPressed()
                    } label: {
                        Image(systemName: "arrowshape.forward.fill")
                    }
                    .disabled(!viewModel.nextWeekEnabled)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                }
                Chart {
                    ForEach(viewModel.weeklyData) {
                        BarMark(
                            x: .value("Calories", $0.calories)
                        )
                        .foregroundStyle(by: .value("Bar Colour", $0.stat))
                    }
                }
                .chartXScale(domain: 0...viewModel.weeklyData.reduce(0, { $0 + $1.calories }))
                .chartForegroundStyleScale(["Burnt": .blue, "To Go": .orange, "Can Eat": .green])
                .padding(.horizontal, 10)
                Chart {
                    ForEach(viewModel.weeklyPlantsData) {
                        BarMark(
                            x: .value("Num Plants", $0.numPlants)
                        )
                        .foregroundStyle(by: .value("Bar Colour", $0.stat))
                    }
                }
                .chartXScale(domain: 0...viewModel.weeklyPlantsData.reduce(0, { $0 + $1.numPlants }))
                .chartForegroundStyleScale(["Eaten": .blue, "To Go": .orange, "Abundance": .purple])
                .padding(.horizontal, 10)
            }
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
        .frame(height: 160)
    }
}
