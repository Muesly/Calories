//
//  MealItemsView.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import SwiftUI

struct MealItemsView: View {
    @ObservedObject var viewModel: MealItemsViewModel

    init(viewModel: MealItemsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("\(viewModel.mealTitle)")

            ForEach(viewModel.mealFoodEntries) { foodEntry in
                HStack {
                    Text("\(foodEntry.timeConsumed!, formatter: itemFormatter)")
                    Text("\(foodEntry.foodDescription)")
                    Text("\(Int(foodEntry.calories)) calories")
                }
            }
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
