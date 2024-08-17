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
    var viewModel: RecordWeightViewModel
    @State private var isShowingFailureToAuthoriseAlert = false
    @State private var isRefreshing = false
    @State private var applied = false
    @State private var showConfetti = false
    
    init(viewModel: RecordWeightViewModel) {
        self.viewModel = viewModel
    }
    
    private var xAxisMarks: [String] {
        let count = viewModel.weightData.count
        guard count > 2 else { return [] }
        
        let numMarks = 4
        let gap = (count - 2) / (numMarks - 1)
        var markIDs = [Int]()
        for markID in 0 ..< numMarks {
            markIDs.append((markID * gap) + 1)
        }
        return markIDs.map { viewModel.weekStr(forDataPoint: viewModel.weightData[$0]) }
    }
    
    private var yAxisMarks: [Int] {
        let weights = viewModel.weightData.map { $0.weight }
        let weightsMin = Int(weights.min() ?? 0)
        let weightsMax = Int(weights.max() ?? 0)
        
        let numMarks = 4
        let gap = (weightsMax - weightsMin) / 3
        var markIDs = [Int]()
        for markID in 0 ..< numMarks {
            markIDs.append((gap * markID) + weightsMin)
        }
        return markIDs.map { Int($0) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    let weights = viewModel.weightData.map { $0.weight }
                    let weightsMin = weights.min() ?? 0
                    let weightsMax = weights.max() ?? 0
                    let deficits = viewModel.weightData.map { $0.deficit }
                    let deficitsMin = deficits.min() ?? 0
                    let deficitsMax = deficits.max() ?? 0
                    Chart {
                        ForEach(viewModel.weightData) { weightDataPoint in
                            BarMark(x: .value("Week", viewModel.weekStr(forDataPoint: weightDataPoint)),
                                    y: .value("Calories", weightDataPoint.deficit))
                            .clipShape(Capsule())
                            .foregroundStyle(Color.blue)
                        }
                        RuleMark(y: .value("Target", -3500))
                            .foregroundStyle(.blue.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                    .padding(.trailing, 40)
                    .chartYScale(domain: deficitsMin...deficitsMax)
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(preset: .aligned, values: xAxisMarks) { mark in
                            AxisValueLabel()
                            AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.blue.opacity(0.3))
                        }
                    }
                    .opacity(isRefreshing ? 0 : 1)
                    
                    Chart {
                        ForEach(viewModel.weightData) { weightDataPoint in
                            LineMark(x: .value("Week", viewModel.weekStr(forDataPoint: weightDataPoint)),
                                     y: .value("Stones", Int(weightDataPoint.weight)))
                            .foregroundStyle(Color.green)
                        }
                        .interpolationMethod(.cardinal)
                    }
                    .padding(.bottom, 25)
                    .chartYScale(domain: weightsMin...weightsMax)
                    .chartYAxis() {
                        AxisMarks(preset: .aligned, values: yAxisMarks) {
                            let value = $0.as(Double.self)!
                            let weightStr = viewModel.weightStr(value)
                            AxisValueLabel {
                                Text(weightStr)
                            }
                        }
                    }
                    .chartXAxis(.hidden)
                    .opacity(isRefreshing ? 0 : 1)
                    if isRefreshing {
                        ProgressView().accessibilityIdentifier("Loading Weight Chart")
                    }
                }
                .padding()
                .frame(height: 300)
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
                        RevealingTextView(text: Binding(get: { viewModel.currentWeight }, set: { _ in }))
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
                                applied = !applied
                                showConfetti = viewModel.hasLostWeight
                                refresh()
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
                    .sensoryFeedback(.success, trigger: applied)
                    Text(viewModel.totalLoss)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Colours.backgroundSecondary)
                .cornerRadius(10)
                Spacer()
            }
            .padding()
            .font(.brand)
            .navigationTitle("Weight over time")
            .toolbar {
                ToolbarItem {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .displayConfetti(isActive: $showConfetti)
            .task {
                isRefreshing = true
                refresh()
            }
            .onChange(of: scenePhase) { _, newPhase in
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
            isRefreshing = false
        }
    }
}
