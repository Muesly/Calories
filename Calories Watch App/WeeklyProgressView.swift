//
//  WeeklyProgressView.swift
//  Calories Watch App
//
//  Created by Tony Short on 16/02/2023.
//

import SwiftUI

struct WeeklyProgressView: View {
    @ObservedObject var viewModel: WeeklyChartViewModel

    @State var weeklyProgress: Double = 0

    init(viewModel: WeeklyChartViewModel = .init(numberOfDays: 2)) {
        self.viewModel = viewModel
    }

    var body: some View {
        ProgressView("Weekly progress to a 1lb weight loss", value: viewModel.weeklyProgress, total: 1)
            .progressViewStyle(LinearProgressViewStyle(tint: viewModel.weeklyProgress == 1 ? .green : .blue))
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

