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

    /// Returns a formatted date string with ordinal day (e.g., "Mon 18th Dec")
    var displayDateWithOrdinal: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let dayOfWeek = formatter.string(from: self)

        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)

        formatter.dateFormat = "MMM"
        let month = formatter.string(from: self)

        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        let dayWithSuffix = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"

        return "\(dayOfWeek) \(dayWithSuffix) \(month)"
    }

    /// Checks if this date is in the same day as another date
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
}
