//
//  MealPickerViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 13/01/2024.
//

import CoreData
import XCTest
@testable import Calories

final class MealPickerViewTests: XCTestCase {
    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testSettingOfMeals() {
        var timeConsumed = dateFromComponents()
        let subject = MealPickerViewModel(timeConsumed: .init(get: {
            timeConsumed
        }, set: { date in
            timeConsumed = date
        }))
        subject.setInitialMealForTimeConsumed()
        XCTAssertEqual(subject.selectedMealName, "Morning Snack")
        XCTAssertTrue(subject.isMealSelected(.init(name: "Morning Snack", icon: "☕️", hour: 10)))
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 10, minute: 0)
        XCTAssertEqual(timeConsumed, dc.date)
    }
}
