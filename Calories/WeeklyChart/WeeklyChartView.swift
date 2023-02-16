//
//  WeeklyChartView.swift
//  Calories
//
//  Created by Tony Short on 14/02/2023.
//

import Charts
import SwiftUI

struct WeeklyChartView: View {
    let viewModel: WeeklyChartViewModel
    @State var daysCaloriesData: [CalorieDataPointsType] = []
    @State var weeklyProgress: Double = 0
    @State var isCalloutShown: Bool = false
    @State var calloutDay: String = ""
    @State var calloutViewDetails: CallOutViewDetails = .init()

    var body: some View {
        VStack(spacing: 40) {
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
            .padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0))
            .frame(height: 250)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
                                showCallout(at: location, proxy: proxy, geometry: geometry)
                            }
                    }
                }
            }
            ZStack {
                if !isCalloutShown {
                    ProgressView("Weekly progress to a 1lb weight loss", value: weeklyProgress, total: 1)
                        .progressViewStyle(LinearProgressViewStyle(tint: weeklyProgress == 1 ? .green : .blue))
                        .padding()
                }
                if isCalloutShown {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Burnt: \(calloutViewDetails.bmr) + \(calloutViewDetails.exercise) = \(calloutViewDetails.burnt)")
                            Text("Consumed: \(calloutViewDetails.caloriesConsumed)")
                            Text("Difference: \(calloutViewDetails.difference)")
                            Text("Deficit goal: \(calloutViewDetails.deficitGoal)")
                            Text("Can eat: \(calloutViewDetails.canEat)")
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Colours.backgroundSecondary)
                    .cornerRadius(10)
                }
            }
            .frame(height: 100)
        }
        .font(.brand)
        .task {
            (daysCaloriesData, weeklyProgress) = await viewModel.getDaysCalorieData()
        }
    }

    func showCallout(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        guard let day: String = proxy.value(atX: xPosition) else {
            return
        }
        if day == calloutDay {
            isCalloutShown = false
            calloutDay = ""
        } else {
            isCalloutShown = true
            Task {
                do {
                    calloutViewDetails = try await viewModel.calloutViewDetails(for: day)
                } catch {
                    print("Failed to fetch callout details")
                }
            }
        }
        calloutDay = day
    }
}
