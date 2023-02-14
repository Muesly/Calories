//
//  HeaderView.swift
//  Calories
//
//  Created by Tony Short on 12/02/2023.
//

import SwiftUI

struct HeaderView: View {
    @ObservedObject var calorieStats: CalorieStats
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Burnt: \(calorieStats.bmr) + \(calorieStats.exercise) = \(calorieStats.combinedExpenditure)")
                Text("Consumed: \(calorieStats.caloriesConsumed)")
            }
            VStack(alignment: .center) {
                Text("Difference: \(calorieStats.difference)")
                Text("Deficit goal: \(calorieStats.deficitGoal)")
                Text("Can eat: \(calorieStats.canEat)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Colours.backgroundSecondary)
        .cornerRadius(10)
    }
}
