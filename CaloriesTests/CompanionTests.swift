//
//  CompanionTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 13/08/2024.
//

import Testing
@testable import Calories

struct CompanionTests {
    @Test func testCompanionReturnsMessageForEarlyMorning() throws {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "Rise and Shine! What’s good for breakfast?")
        #expect(scheduledHour == 7)
    }

    @Test func testCompanionReturnsMessageForMidMorning() throws {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 1),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "Time for a quick stretch! Your muscles will thank you.")
        #expect(scheduledHour == 10)
    }

    @Test func testCompanionReturnsMessageForAnyTime() throws {
        let sut = Companion(messageDetails: messageDetails)
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 2),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "The only bad workout is the one you didn't do.")
        #expect(scheduledHour == 9)
    }

    @Test func testMessageOnSuitableDay() throws {
        let messageDetails = [CompanionMessage(message: "Some advice for Tuesday", timeOfDay: .earlyMorning, validDay: .tuesday)]
        let sut = Companion(messageDetails: messageDetails)
        #expect(throws: CompanionError.NoValidMessages) {
            let (_, _) = try sut.nextMotivationalMessage(weekday: 0,
                                                         randomPicker: MockRandomPicker(numberPick: 0),
                                                         weeklyWeightChange: 0,
                                                         monthlyWeightChange: 0)
        }
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 1,
                                                                       randomPicker: MockRandomPicker(numberPick: 0),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "Some advice for Tuesday")
        #expect(scheduledHour == 7)
    }

    @Test func testMessageOnWeeklyWeightLossScenario() throws {
        let messageDetails = [CompanionMessage(message: "You've lost some weight", validScenario: .weeklyWeightLoss)]
        let sut = Companion(messageDetails: messageDetails)
        #expect(throws: CompanionError.NoValidMessages) {
            let (_, _) = try sut.nextMotivationalMessage(weekday: 0,
                                                         randomPicker: MockRandomPicker(numberPick: 0),
                                                         weeklyWeightChange: 0,
                                                         monthlyWeightChange: 0)
        }

        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 0),
                                                                       weeklyWeightChange: -1,
                                                                       monthlyWeightChange: 0)
        #expect(message == "You've lost some weight")
        #expect(scheduledHour == 7)
    }

    @Test func testMessageOnMonthlyWeightLossScenario() throws {
        let messageDetails = [CompanionMessage(message: "You've lost some weight", validScenario: .monthlyWeightLoss)]
        let sut = Companion(messageDetails: messageDetails)
        #expect(throws: CompanionError.NoValidMessages) {
            let (_, _) = try sut.nextMotivationalMessage(weekday: 0,
                                                         randomPicker: MockRandomPicker(numberPick: 0),
                                                         weeklyWeightChange: 0,
                                                         monthlyWeightChange: -1)
        }

        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 0),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: -2)
        #expect(message == "You've lost some weight")
        #expect(scheduledHour == 7)
    }

    @Test func testMessageOnWeeklyWeightGainScenario() throws {
        let messageDetails = [CompanionMessage(message: "You've gained some weight", validScenario: .weeklyWeightGain)]
        let sut = Companion(messageDetails: messageDetails)
        #expect(throws: CompanionError.NoValidMessages) {
            let (_, _) = try sut.nextMotivationalMessage(weekday: 0,
                                                         randomPicker: MockRandomPicker(numberPick: 0),
                                                         weeklyWeightChange: 0,
                                                         monthlyWeightChange: 0)
        }

        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 0),
                                                                       weeklyWeightChange: 1,
                                                                       monthlyWeightChange: 0)
        #expect(message == "You've gained some weight")
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
