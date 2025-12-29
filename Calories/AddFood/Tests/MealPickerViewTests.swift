//
//  MealPickerViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 13/01/2024.
//

import Testing

@testable import Calories

@Suite("MealPickerViewModel Tests")
@MainActor
struct MealPickerViewTests {
    func dateFromComponents() -> Date {
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    @Test("Setting of meals")
    func testSettingOfMeals() {
        var timeConsumed = dateFromComponents()
        let subject = MealPickerViewModel(
            timeConsumed: .init(
                get: {
                    timeConsumed
                },
                set: { date in
                    timeConsumed = date
                }))
        subject.setInitialMealForTimeConsumed()
        #expect(subject.selectedMealName == "Morning Snack")
        #expect(subject.isMealSelected(.init(name: "Morning Snack", icon: "☕️", hour: 10)))
        let dc = DateComponents(
            calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 10, minute: 0)
        #expect(timeConsumed == dc.date)
    }
}
