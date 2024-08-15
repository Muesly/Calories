//
//  Companion.swift
//  Calories
//
//  Created by Tony Short on 13/08/2024.
//

import Foundation

struct Companion {
    static let messageDetails: [CompanionMessageDetails] = [
        CompanionMessageDetails(message: "Rise and Shine! What’s good for breakfast?"),
        CompanionMessageDetails(message: "Time for a quick stretch! Your muscles will thank you."),
        CompanionMessageDetails(message: "The only bad workout is the one you didn't do.")
    ]

    static func nextMotivationalMessage() -> String {
        let validMessages = messageDetails
        return validMessages.first!.message
    }
}

struct CompanionMessageDetails {
    let message: String

    init(message: String) {
        self.message = message
    }
}
