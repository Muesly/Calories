//
//  Companion.swift
//  Calories
//
//  Created by Tony Short on 13/08/2024.
//

import Foundation

struct Companion {
    let messageDetails: [CompanionMessage]

    func nextMotivationalMessage(weekday: Int, randomPicker: RandomPickerType = RandomPicker()) -> (String, Int) {
        let validMessages = messageDetails.filter { $0.validForWeekday(weekday) }
        let chosenMessage = validMessages[randomPicker.pick(fromNumberOfItems: validMessages.count)]
        if let scheduledHour = chosenMessage.scheduledHour {
            return (chosenMessage.message, scheduledHour)
        } else {
            let randomScheduledHour = 7 + randomPicker.pick(fromNumberOfItems: 12)
            return (chosenMessage.message, randomScheduledHour)
        }
    }
}

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

protocol RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int
}

struct RandomPicker: RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int {
        Int.random(in: 0..<numberOfItems)
    }
}

