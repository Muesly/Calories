//
//  Companion.swift
//  Calories
//
//  Created by Tony Short on 13/08/2024.
//

import Foundation

struct Companion {
    let messageDetails: [CompanionMessageDetails]

    func nextMotivationalMessage(randomPicker: RandomPickerType = RandomPicker()) -> (String, Int) {
        let validMessages = messageDetails
        let chosenMessage = validMessages[randomPicker.pick(fromNumberOfItems: validMessages.count)]
        if let scheduledHour = chosenMessage.scheduledHour {
            return (chosenMessage.message, scheduledHour)
        } else {
            let randomScheduledHour = 7 + randomPicker.pick(fromNumberOfItems: 12)
            return (chosenMessage.message, randomScheduledHour)
        }
    }
}

struct CompanionMessageDetails {
    let message: String
    let timeOfDay: TimeOfDay

    var scheduledHour: Int? {
        switch timeOfDay {
        case .earlyMorning:
            7
        case .midMorning:
            10
        case .anyTime:
            nil
        }
    }
}

enum TimeOfDay: CaseIterable {
    case earlyMorning
    case midMorning
    case anyTime
}

protocol RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int
}

struct RandomPicker: RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int {
        Int.random(in: 0..<numberOfItems)
    }
}

