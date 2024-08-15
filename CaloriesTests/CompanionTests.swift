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
        let message = Companion.nextMotivationalMessage()
        #expect(message == "Rise and Shine! What’s good for breakfast?")
    }
}
