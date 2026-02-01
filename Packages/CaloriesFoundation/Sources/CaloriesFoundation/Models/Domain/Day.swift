//
//  Day.swift
//  Calories
//
//  Created by Tony Short on 02/03/2023.
//

import Foundation

public class Day: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public var meals = [Meal]()
    private static var df: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df
    }

    public init(date: Date) {
        self.date = date
    }

    public var title: String {
        Day.df.string(from: date)
    }

    public static func == (lhs: Day, rhs: Day) -> Bool {
        return (lhs.date == rhs.date) && (lhs.meals == rhs.meals)
    }
}
