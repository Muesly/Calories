//
//  MealPickerView.swift
//  Calories
//
//  Created by Tony Short on 11/01/2024.
//

import Foundation
import SwiftUI

struct MealToPick: Hashable {
    let name: String
    let icon: String
    let hour: Int
}

struct MealPickerView: View {
    let viewModel: MealPickerViewModel

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                ForEach(viewModel.meals, id: \.self) { mealToPick in
                    let isSelected = viewModel.isMealSelected(mealToPick)
                    Button(mealToPick.icon) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 1)) {
                            viewModel.selectMeal(mealToPick)
                        }
                    }
                    .background(isSelected ? Color.green : Color.clear)
                    .font(.system(size: isSelected ? 56 : 40))
                    .cornerRadius(8.0)
                }
            }
            Text(viewModel.selectedMealName)
                .bold()
            DatePicker("Date:", selection: viewModel.$timeConsumed, displayedComponents: .date)
        }
        .onAppear {
            viewModel.setInitialMealForTimeConsumed()
        }
    }
}

struct MealPickerView_Previews: PreviewProvider {
    static var previews: some View {
        MealPickerView(viewModel: MealPickerViewModel(timeConsumed: .constant(Date())))
    }
}

class MealPickerViewModel {
    @Binding var timeConsumed: Date
    let meals: [MealToPick] = [.init(name: "Breakfast", icon: "🥣", hour: 8),
                               .init(name: "Morning Snack", icon: "☕️", hour: 10),
                               .init(name: "Lunch", icon: "🥗", hour: 12),
                               .init(name: "Afternoon Snack", icon: "🥜", hour: 14),
                               .init(name: "Dinner", icon: "🍲", hour: 18),
                               .init(name: "Evening Snack", icon: "🍺", hour: 20)]

    init(timeConsumed: Binding<Date>) {
        self._timeConsumed = timeConsumed
    }

    private var hourOfTimeConsumed: Int {
        Calendar.current.dateComponents([.hour], from: timeConsumed).hour!
    }

    var selectedMealName: String {
        return meals.first { $0.hour == hourOfTimeConsumed }?.name ?? ""
    }

    func setInitialMealForTimeConsumed() {
        let hour = hourOfTimeConsumed
        let initialMeal = meals.reversed().first { hour >= $0.hour } ?? meals.first!
        selectMeal(initialMeal)
    }

    func selectMeal(_ meal: MealToPick) {
        timeConsumed = Calendar.current.date(bySettingHour: meal.hour, minute: 0, second: 0, of: timeConsumed)!
    }

    func isMealSelected(_ meal: MealToPick) -> Bool {
        return meal.hour == hourOfTimeConsumed
    }
}
