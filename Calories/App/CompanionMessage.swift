//
//  CompanionMessage.swift
//  Calories
//
//  Created by Tony Short on 15/08/2024.
//

import Foundation

struct CompanionMessage {
    let message: String
    let timeOfDay: TimeOfDay?
    let validDay: DayOfWeek?

    init(message: String,
         timeOfDay: TimeOfDay? = nil,
         validDay: DayOfWeek? = nil) {
        self.message = message
        self.timeOfDay = timeOfDay
        self.validDay = validDay
    }

    var scheduledHour: Int? {
        guard let timeOfDay else { return nil }

        switch timeOfDay {
        case .earlyMorning:
            return 7
        case .midMorning:
            return 10
        case .lunch:
            return 12
        case .afternoon:
            return 15
        case .earlyEvening:
            return 18
        case .lateEvening:
            return 21
        }
    }

    func validForWeekday(_ weekday: Int) -> Bool {
        guard let validDay else {
            return true
        }
        return DayOfWeek.allCases.firstIndex(of: validDay) == weekday
    }
}

enum TimeOfDay: CaseIterable {
    case earlyMorning
    case midMorning
    case lunch
    case afternoon
    case earlyEvening
    case lateEvening
}

enum DayOfWeek: CaseIterable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}
