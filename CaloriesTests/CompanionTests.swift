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
        let (message, scheduledHour) = sut.nextMotivationalMessage(weekday: 0, randomPicker: MockRandomPicker())
        #expect(message == "Rise and Shine! What’s good for breakfast?")
        #expect(scheduledHour == 7)
    }

    @Test func testCompanionReturnsMessageForMidMorning() {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = sut.nextMotivationalMessage(weekday: 0, randomPicker: MockRandomPicker(numberPick: 1))
        #expect(message == "Time for a quick stretch! Your muscles will thank you.")
        #expect(scheduledHour == 10)
    }

    @Test func testCompanionReturnsMessageForAnyTime() {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = sut.nextMotivationalMessage(weekday: 0, randomPicker: MockRandomPicker(numberPick: 2))
        #expect(message == "The only bad workout is the one you didn't do.")
        #expect(scheduledHour == 9)
    }

    @Test func testMessageIgnoredIfNotSuitableDay() {
        let messageDetails = [CompanionMessage(message: "Some advice for Tuesday", timeOfDay: .earlyMorning, validDay: .tuesday),
                              CompanionMessage(message: "Rise and Shine! What’s good for breakfast?", timeOfDay: .earlyMorning)]
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = sut.nextMotivationalMessage(weekday: 0, randomPicker: MockRandomPicker(numberPick: 0))
        #expect(message == "Rise and Shine! What’s good for breakfast?")
        #expect(scheduledHour == 7)
    }

    private let messageDetails = [
        CompanionMessage(message: "Rise and Shine! What’s good for breakfast?", timeOfDay: .earlyMorning),
        CompanionMessage(message: "Time for a quick stretch! Your muscles will thank you.", timeOfDay: .midMorning),
        CompanionMessage(message: "The only bad workout is the one you didn't do.")
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
