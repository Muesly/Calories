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
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("BMR: \(calorieStats.bmr)")
                Text("Exercise: \(calorieStats.exercise)")
                Text("Combined: \(calorieStats.combinedExpenditure)")
            }
            VStack(alignment: .leading) {
                Text("Consumption: \(calorieStats.caloriesConsumed)")
                Text("Difference: \(calorieStats.difference)")
                Text("Deficit goal: \(calorieStats.deficitGoal)")
                Text("Can eat: \(calorieStats.canEat)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color("mintGreen").opacity(0.3))
        .cornerRadius(10)
    }
}
