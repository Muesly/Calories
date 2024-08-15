//
//  CompanionTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 13/08/2024.
//

import Testing
@testable import Calories

struct CompanionTests {
    @Test func testCompanionReturnsMessageForEarlyMorning() {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = sut.nextMotivationalMessage(randomPicker: MockRandomPicker())
        #expect(message == "Rise and Shine! What’s good for breakfast?")
        #expect(scheduledHour == 7)
    }

    @Test func testCompanionReturnsMessageForMidMorning() {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = sut.nextMotivationalMessage(randomPicker: MockRandomPicker(numberPick: 1))
        #expect(message == "Time for a quick stretch! Your muscles will thank you.")
        #expect(scheduledHour == 10)
    }

    @Test func testCompanionReturnsMessageForAnyTime() {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = sut.nextMotivationalMessage(randomPicker: MockRandomPicker(numberPick: 2))
        #expect(message == "The only bad workout is the one you didn't do.")
        #expect(scheduledHour == 9)
    }

    private let messageDetails = [
        CompanionMessageDetails(message: "Rise and Shine! What’s good for breakfast?", timeOfDay: .earlyMorning),
        CompanionMessageDetails(message: "Time for a quick stretch! Your muscles will thank you.", timeOfDay: .midMorning),
        CompanionMessageDetails(message: "The only bad workout is the one you didn't do.", timeOfDay: .anyTime)
    ]
}

struct MockRandomPicker: RandomPickerType {
    let numberPick: Int

    init(numberPick: Int = 0) {
        self.numberPick = numberPick
    }

    func pick(fromNumberOfItems numberOfItems: Int) -> Int {
        numberPick
    }
}
