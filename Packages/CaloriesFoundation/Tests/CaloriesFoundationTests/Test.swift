//
//  Test.swift
//  CaloriesFoundation
//
//  Created by Tony Short on 01/02/2026.
//

import Testing
import CaloriesFoundation

struct Test {
    @Test func fuzzyMatching() async throws {
        let subject = "Test Str"
        let match = subject.fuzzyMatch("Test")
        #expect(match == true)
    }
}
