//
//  Date+Extensions.swift
//  Calories
//
//  Created by Tony Short on 05/03/2023.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        startOfDay.addingTimeInterval(86399)
    }

    var startOfWeek: Date {
        Calendar(identifier: .iso8601).dateComponents(
            [.calendar, .yearForWeekOfYear, .weekOfYear], from: self
        ).date!
    }
}
