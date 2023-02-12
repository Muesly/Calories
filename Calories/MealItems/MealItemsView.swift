//
//  MealItemsView.swift
//  Calories
//
//  Created by Tony Short on 11/02/2023.
//

import Foundation
import SwiftUI

struct MealItemsView: View {
    let viewModel: MealItemsViewModel

    init(viewModel: MealItemsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("\(viewModel.getMealTitle())")

            ForEach(viewModel.getMealFoodEntries()) { foodEntry in
                HStack {
                    Text("\(foodEntry.timeConsumed!, formatter: itemFormatter)")
                    Text("\(foodEntry.foodDescription)")
                    Text("\(Int(foodEntry.calories)) calories")
                }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()
