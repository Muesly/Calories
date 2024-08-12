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
    @State var isCalloutShown: Bool = false
    @State var calloutDay: String = ""
    @State var calloutViewDetails: CallOutViewDetails = .init()

    var body: some View {
        VStack(spacing: 20) {
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
            .chartForegroundStyleScale(["Burnt": .blue, "Consumed": .cyan, "Good": .green, "Ok": .orange, "Bad": .red])
            ZStack {
                if !isCalloutShown {
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
                                .foregroundStyle(by: .value("Production", $0.stat))
                            }
                        }
                        .chartXScale(domain: 0...viewModel.weeklyData.reduce(0, { $0 + $1.calories }))
                        .chartForegroundStyleScale(["Burnt": .blue, "Can Eat": .green, "To Go": .orange])
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                }
                if isCalloutShown {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Date: \(calloutViewDetails.dateStr)")
                            Text("Burnt: \(calloutViewDetails.bmr) + \(calloutViewDetails.exercise) = \(calloutViewDetails.burnt)")
                            Text("Consumed: \(calloutViewDetails.caloriesConsumed)")
                            Text("Difference: \(calloutViewDetails.difference)")
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
            await viewModel.fetchDaysCalorieData()
        }
    }

    private func showCallout(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else {
            return
        }
        let xPosition = location.x - geometry[plotFrame].origin.x
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
