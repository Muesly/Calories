//
//  CompanionTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 13/08/2024.
//

import Foundation
import Testing
@testable import Calories

@MainActor
struct CompanionTests {
    @Test func companionReturnsMessageForEarlyMorning() throws {
        let sut = createCompanionSubject()
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "Rise and Shine! What’s good for breakfast?")
        #expect(scheduledHour == 7)
    }

    @Test func companionReturnsMessageForMidMorning() throws {
        let sut = createCompanionSubject()
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 1),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "Time for a quick stretch! Your muscles will thank you.")
        #expect(scheduledHour == 10)
    }

    @Test func companionReturnsMessageForAnyTime() throws {
        let sut = createCompanionSubject()
        let (message, scheduledHour) = try sut.nextMotivationalMessage(weekday: 0,
                                                                       randomPicker: MockRandomPicker(numberPick: 2),
                                                                       weeklyWeightChange: 0,
                                                                       monthlyWeightChange: 0)
        #expect(message == "The only bad workout is the one you didn't do.")
        #expect(scheduledHour == 9)
    }

    @Test func messageOnSuitableDay() throws {
        let messageDetails = [CompanionMessage(message: "Some advice for Tuesday", timeOfDay: .earlyMorning, validDay: .tuesday)]
        let sut = Companion(messageDetails: messageDetails, notificationSender: StubbedNotificationSender())
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

    @Test func messageOnWeeklyWeightLossScenario() throws {
        let messageDetails = [CompanionMessage(message: "You've lost some weight", validScenario: .weeklyWeightLoss)]
        let sut = Companion(messageDetails: messageDetails, notificationSender: StubbedNotificationSender())
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

    @Test func messageOnMonthlyWeightLossScenario() throws {
        let messageDetails = [CompanionMessage(message: "You've lost some weight", validScenario: .monthlyWeightLoss)]
        let sut = Companion(messageDetails: messageDetails, notificationSender: StubbedNotificationSender())
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

    @Test func messageOnWeeklyWeightGainScenario() throws {
        let messageDetails = [CompanionMessage(message: "You've gained some weight", validScenario: .weeklyWeightGain)]
        let sut = Companion(messageDetails: messageDetails, notificationSender: StubbedNotificationSender())
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

    @Test func schedulesNotificationForTomorrow() async throws {
        let sut = createCompanionSubject()
        #expect(await !sut.notificationSender.hasPendingRequests())

        try await sut.scheduleTomorrowsMotivationalMessage(context: .init(date: dateFromComponents(),
                                                                          weeklyWeightChange: 0,
                                                                          monthlyWeightChange: 0))

        #expect(await sut.notificationSender.hasPendingRequests())
        let currentWeekday = Calendar.current.dateComponents([.weekday], from: dateFromComponents()).weekday!
        #expect(currentWeekday == 2)
        let scheduledWeekday = (sut.notificationSender as? StubbedNotificationSender)?.requestDates.first?.weekday
        #expect(scheduledWeekday == 3)
    }

    @Test func doesNotSchedulesNotificationIfAlreadyOneScheduled() async throws {
        let sut = createCompanionSubject()
        #expect(await !sut.notificationSender.hasPendingRequests())

        try await sut.scheduleTomorrowsMotivationalMessage(context: .init(date: dateFromComponents(),
                                                                          weeklyWeightChange: 0,
                                                                          monthlyWeightChange: 0))
        try await sut.scheduleTomorrowsMotivationalMessage(context: .init(date: dateFromComponents(),
                                                                          weeklyWeightChange: 0,
                                                                          monthlyWeightChange: 0))

        #expect(await sut.notificationSender.hasPendingRequests())
        #expect((sut.notificationSender as? StubbedNotificationSender)?.requestDates.count == 1)
    }

    private func createCompanionSubject() -> Companion {
        Companion(messageDetails: messageDetails, notificationSender: StubbedNotificationSender())
    }

    private let messageDetails = [
        CompanionMessage(message: "Rise and Shine! What’s good for breakfast?", timeOfDay: .earlyMorning),
        CompanionMessage(message: "Time for a quick stretch! Your muscles will thank you.", timeOfDay: .midMorning),
        CompanionMessage(message: "The only bad workout is the one you didn't do.")
    ]

    private func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2024, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

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
