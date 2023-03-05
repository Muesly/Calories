//
//  Day.swift
//  Calories
//
//  Created by Tony Short on 02/03/2023.
//

import Foundation

class Day: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    var meals = [Meal]()
    private static var df: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df
    }

    init(date: Date) {
        self.date = date
    }

    var title: String {
        Day.df.string(from: date)
    }

    static func == (lhs: Day, rhs: Day) -> Bool {
        return (lhs.date == rhs.date) && (lhs.meals == rhs.meals)
    }
}
