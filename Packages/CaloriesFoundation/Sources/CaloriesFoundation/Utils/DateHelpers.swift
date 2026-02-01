//
//  DateHelpers.swift
//  Calories
//
//  Created by Tony Short on 17/01/2026.
//

import Foundation

extension Date {
    /// Returns the Monday to plan from:
    /// - Mon-Wed: this week's Monday
    /// - Thu-Sun: next week's Monday
    public var startOfPlanningWeek: Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)

        // Calendar weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        // Monday = 2, Tuesday = 3, Wednesday = 4
        let isEarlyInWeek = (2...4).contains(weekday)

        // Find this week's Monday
        let thisMonday = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!

        if isEarlyInWeek {
            return thisMonday
        } else {
            // Return next Monday
            return calendar.date(byAdding: .weekOfYear, value: 1, to: thisMonday)!
        }
    }
}
