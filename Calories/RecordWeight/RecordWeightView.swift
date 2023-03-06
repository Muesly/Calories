//
//  RecordWeightView.swift
//  Calories
//
//  Created by Tony Short on 20/02/2023.
//

import Charts
import Foundation
import SwiftUI

struct RecordWeightView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var viewModel: RecordWeightViewModel
    @State private var isShowingFailureToAuthoriseAlert = false

    init(viewModel: RecordWeightViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                Chart {
                    ForEach(viewModel.weightData) { weightDataPoint in
                        LineMark(x: .value("Week", viewModel.weekStr(forDataPoint: weightDataPoint)),
                                 y: .value("Stones", weightDataPoint.stones))
                        .foregroundStyle(.green)
                    }
                }
                .chartYAxis {
                    AxisMarks() { yValue in
                        let yValueStr = WeightDataPoint.poundsToStoneAndPoundsStr(stones: yValue.as(Double.self)!)
                        AxisValueLabel {
                            Text("\(yValueStr)")
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .padding()
                .frame(height: 250)
                Chart {
                    ForEach(viewModel.weightData) { weightDataPoint in
                        BarMark(x: .value("Week", viewModel.weekStr(forDataPoint: weightDataPoint)),
                                y: .value("Calories", weightDataPoint.deficit))
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .padding()
                .frame(height: 150)
                VStack {
                    Text("Current Weight")
                    HStack {
                        Button {
                            viewModel.decreaseWeight()
                        } label: {
                            Image(systemName: "minus.circle")
                                .tint(Colours.foregroundPrimary)
                                .padding(5)
                        }
                        Text(viewModel.currentWeight)
                            .lineLimit(1)
                            .bold()
                        Button {
                            viewModel.increaseWeight()
                        } label: {
                            Image(systemName: "plus.circle")
                                .tint(Colours.foregroundPrimary)
                                .padding(5)
                        }
                    }
                    Button {
                        Task {
                            do {
                                try await viewModel.applyNewWeight()
                            } catch {
                                print("Failed to apply new weight")
                            }
                        }
                    } label: {
                        Text("Apply")
                            .padding(5)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    Text(viewModel.totalLoss)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Colours.backgroundSecondary)
                .cornerRadius(10)
            }
            .padding()
            .font(.brand)
            .navigationTitle("Record Weight")
            .toolbar {
                ToolbarItem {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                refresh()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    refresh()
                }
            }
            .alert("Failed to access vehicle health",
                   isPresented: $isShowingFailureToAuthoriseAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func refresh() {
        Task {
            do {
                try await viewModel.fetchWeightData()
            } catch {
                isShowingFailureToAuthoriseAlert = true
            }
        }
    }
}
