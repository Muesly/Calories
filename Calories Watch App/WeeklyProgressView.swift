//
//  WeeklyProgressView.swift
//  Calories Watch App
//
//  Created by Tony Short on 16/02/2023.
//

import Charts
import SwiftUI

struct WeeklyProgressView: View {
    @ObservedObject var viewModel: WeeklyChartViewModel

    @State var weeklyProgress: Double = 0

    init(viewModel: WeeklyChartViewModel = .init(numberOfDays: 2)) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Progress from \(viewModel.startOfWeek)")
            Chart {
                ForEach(viewModel.weeklyData) {
                    BarMark(
                        x: .value("Calories", $0.calories)
                    )
                    .foregroundStyle(by: .value("Production", $0.stat))
                }
            }
        }
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

