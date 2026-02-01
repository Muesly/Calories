//
//  WeeklyChartView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Charts
import SwiftUI
import CaloriesFoundation

struct WeeklyChartView: View {
    var viewModel: WeeklyChartViewModel

    var body: some View {
        VStack(spacing: 20) {
            DaysCaloriesChart(viewModel: viewModel)
            WeekSelector(viewModel: viewModel)
            WeeklyProgressChart(viewModel: viewModel)
        }
        .font(.brand)
    }
}

struct DaysCaloriesChart: View {
    let viewModel: WeeklyChartViewModel

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
            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            .frame(height: 240)
            .chartForegroundStyleScale([
                "Burnt": .blue, "Consumed": .cyan, "Good": .green, "Ok": .orange, "Bad": .red,
            ])
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount > 0 {
                            if viewModel.previousWeekEnabled {
                                viewModel.previousWeekPressed()
                            }
                        } else {
                            if viewModel.nextWeekEnabled {
                                viewModel.nextWeekPressed()
                            }
                        }
                    }
                }
        )
    }
}

struct WeekSelector: View {
    let viewModel: WeeklyChartViewModel

    var body: some View {
        HStack {
            Button {
                viewModel.previousWeekPressed()
            } label: {
                Image(systemName: "arrowshape.backward.fill")
            }
            .disabled(!viewModel.previousWeekEnabled)
            .foregroundColor(.blue)
            .buttonStyle(.plain)
            Spacer()
            Text(viewModel.weekStr)
            Spacer()
            Button {
                viewModel.nextWeekPressed()
            } label: {
                Image(systemName: "arrowshape.forward.fill")
            }
            .disabled(!viewModel.nextWeekEnabled)
            .foregroundColor(.blue)
            .buttonStyle(.plain)
        }
    }
}

struct WeeklyProgressChart: View {
    let viewModel: WeeklyChartViewModel
    let chartTitleFont = Font.custom("Avenir Next", size: 10)

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Text("Estimated Weight Loss")
                        .font(chartTitleFont)
                    Chart {
                        ForEach(viewModel.weeklyData) {
                            BarMark(
                                x: .value("Estimated Weight Loss", $0.weightLossInLbs)
                            )
                            .foregroundStyle(by: .value("Bar Colour", $0.stat))
                        }
                    }
                    .chartXScale(
                        domain: viewModel.weeklyDataMinX...viewModel.weeklyDataMaxX,
                        range: .plotDimension(padding: 20)
                    )
                    .chartForegroundStyleScale([
                        "Bad": .red, "Good": .green, "To Go": .gray, "Can Eat": .blue,
                    ])
                    Text("Different Plants Eaten")
                        .font(chartTitleFont)
                        .padding(.top, 5)
                    Chart {
                        ForEach(viewModel.weeklyPlantsData) {
                            BarMark(
                                x: .value("Plants", $0.numPlants)
                            )
                            .foregroundStyle(by: .value("Bar Colour", $0.stat))
                        }
                    }
                    .chartXScale(
                        domain: 0...viewModel.weeklyPlantsDataMaxX,
                        range: .plotDimension(padding: 20)
                    )
                    .chartForegroundStyleScale([
                        "Eaten": Color.yellow, "To Go": .gray, "Abundance": .green,
                    ])
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            }
            .frame(height: 160)
        }
    }
}
