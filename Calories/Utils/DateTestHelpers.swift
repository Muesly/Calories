//
//  DateTestHelpers.swift
//  Calories
//
//  Created by Tony Short on 17/01/2026.
//

import Foundation

extension Date {
    static var testReference: Date {
        Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 1,
                day: 1,
                hour: 12,
                minute: 0
            ))!
    }
}
