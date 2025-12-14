//
//  DayMealSelectionView.swift
//  Calories
//
//  Created by Tony Short on 14/12/2025.
//

import SwiftUI

struct DayMealSelectionView<Card: View>: View {
    let date: Date
    private let mealList: [MealType] = [.breakfast, .lunch, .dinner]
    @ViewBuilder let card: (MealType, Date) -> Card

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Colours.foregroundPrimary)

            HStack(alignment: .top, spacing: 8) {
                ForEach(mealList, id: \.self) { mealType in
                    card(mealType, date)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let dayOfWeek = formatter.string(from: date)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)

        formatter.dateFormat = "MMM"
        let month = formatter.string(from: date)

        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        let dayWithSuffix = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"

        return "\(dayOfWeek) \(dayWithSuffix) \(month)"
    }
}
