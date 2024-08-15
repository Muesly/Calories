//
//  CompanionTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 13/08/2024.
//

import Testing
@testable import Calories

struct CompanionTests {
    @Test func testCompanionReturnsMessage() {
        let message = Companion.nextMotivationalMessage(randomPicker: MockRandomPicker())
        #expect(message == "Rise and Shine! What’s good for breakfast?")
    }
}

struct MockRandomPicker: RandomPickerType {
    func pick(fromNumberOfItems numberOfItems: Int) -> Int {
        0
    }
}
