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
    let validScenario: Scenario?

    init(
        message: String,
        timeOfDay: TimeOfDay? = nil,
        validDay: DayOfWeek? = nil,
        validScenario: Scenario? = nil
    ) {
        self.message = message
        self.timeOfDay = timeOfDay
        self.validDay = validDay
        self.validScenario = validScenario
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

    func valid(forWeekday weekday: Int, scenario: Scenario?) -> Bool {
        if let validDay {
            return DayOfWeek.allCases.firstIndex(of: validDay) == weekday
        }
        if let validScenario {
            if let scenario {
                return scenario == validScenario
            } else {
                return false
            }
        }
        return true
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

enum DayOfWeek: String, CaseIterable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

enum Scenario {
    case weeklyWeightLoss
    case monthlyWeightLoss
    case weeklyWeightGain
}
