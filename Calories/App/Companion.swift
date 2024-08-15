//
//  Companion.swift
//  Calories
//
//  Created by Tony Short on 13/08/2024.
//

import Foundation

struct Companion {
    private let messageDetails: [CompanionMessage]

    init(messageDetails: [CompanionMessage]) {
        self.messageDetails = messageDetails
    }

    func nextMotivationalMessage(weekday: Int,
                                 randomPicker: RandomPickerType = RandomPicker(),
                                 weeklyWeightChange: Int,
                                 monthlyWeightChange: Int) throws -> (String, Int) {
        var scenario: Scenario?

        if weeklyWeightChange > 0 {
            scenario = .weeklyWeightGain
        } else if monthlyWeightChange < -1 {
            scenario = .monthlyWeightLoss
        } else if weeklyWeightChange < 0 {
            scenario = .weeklyWeightLoss
        }

        let validMessages = messageDetails.filter { $0.valid(forWeekday: weekday, scenario: scenario) }
        let chosenMessageID = randomPicker.pick(fromNumberOfItems: validMessages.count)
        if chosenMessageID >= validMessages.count {
            throw CompanionError.NoValidMessages
        }
        let chosenMessage = validMessages[chosenMessageID]
        if let scheduledHour = chosenMessage.scheduledHour {
            return (chosenMessage.message, scheduledHour)
        } else {
            let randomScheduledHour = 7 + randomPicker.pick(fromNumberOfItems: 12)
            return (chosenMessage.message, randomScheduledHour)
        }
    }

    static let defaultMessages: [CompanionMessage] = [
        CompanionMessage(message: "Rise and Shine! What’s good for breakfast? 🍳", timeOfDay: .earlyMorning),
        CompanionMessage(message: "Time for a quick stretch! Your muscles will thank you 🙆", timeOfDay: .midMorning),
        CompanionMessage(message: "The only bad workout is the one you didn't do.", timeOfDay: .earlyEvening),
        CompanionMessage(message: "Going in to work? Take some 🥜.", timeOfDay: .earlyMorning, validDay: .thursday),
        CompanionMessage(message: "What exercise can you commit to next week?", timeOfDay: .earlyEvening, validDay: .sunday),
        CompanionMessage(message: "Feeling the slump? A quick walk or some 🥜 can re-energise.", timeOfDay: .afternoon),
        CompanionMessage(message: "Put some time into finding some delicious recipes next week 🥗", validDay: .wednesday),
        CompanionMessage(message: "Small progress is still progress. Keep going! 📉"),
        CompanionMessage(message: "Your body can do so much more than we ask of it 💪"),
        CompanionMessage(message: "Your body craves movement 🚶"),
        CompanionMessage(message: "It can sometimes take time for changes to take effect. Stay strong!"),
        CompanionMessage(message: "Remember the 80:20 rule."),
        CompanionMessage(message: "How did this week go? Take a moment to dial up the good and plan for a strong next week 👏", timeOfDay: .afternoon, validDay: .sunday),
        CompanionMessage(message: "Your future self will thank you for caring about your body today 🫶"),
        CompanionMessage(message: "Every good day starts after good sleep 💤", timeOfDay: .lateEvening),
        CompanionMessage(message: "Your body is bunch of cells needing the right kind of nutrition."),
        CompanionMessage(message: "FEAR = Face Everything And Rise ⛰️"),
        CompanionMessage(message: "Success is the ability to go from one failure to another with no less enthusiasm."),
        CompanionMessage(message: "Think about the order: Fibre 🥬, Protein 🥩, Carbs 🍚, then Exercise🚶", timeOfDay: .lunch),
        CompanionMessage(message: "What foods could you buy today to be healthy additions to our cupboards or fridge? 🍱"),
        CompanionMessage(message: "Cut down on UPFs - food like manufactured substances. 🍭"),
        CompanionMessage(message: "Stress in ourselves is damaging, and contagious to others 😫", timeOfDay: .midMorning),
        CompanionMessage(message: "Take a couple of minutes to meditate 🧘"),
        CompanionMessage(message: "You’ve done so well to lose another bit of weight! Keep going 📉", validScenario: .weeklyWeightLoss),
        CompanionMessage(message: "Don’t worry about the blip yesterday. It’s a marathon, not a sprint.", validScenario: .weeklyWeightGain),
        CompanionMessage(message: "You’ve done really well over the last month 👏", validScenario: .monthlyWeightLoss),
    ]
}

enum CompanionError: Error {
    case NoValidMessages
}
