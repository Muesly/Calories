//
//  MealItemsView.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import SwiftUI

struct MealItemsView: View {
    var viewModel: MealItemsViewModel

    init(viewModel: MealItemsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("\(viewModel.mealTitle)")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
        .padding()
        .onAppear {
            viewModel.fetchMealFoodEntries()
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()
