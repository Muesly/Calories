//
//  WeeklyChartViewModelTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 15/02/2023.
//

import CoreData
import XCTest
@testable import Calories

final class WeeklyChartViewModelTests: XCTestCase {
    var controller: PersistenceController!
    var container: NSPersistentContainer {
        controller.container
    }
    var context: NSManagedObjectContext {
        container.viewContext
    }

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
    }

    override func tearDownWithError() throws {
        controller = nil
    }

    func testCalloutViewDetails() async throws {
        let mockHealthStore = MockHealthStore()
        mockHealthStore.bmr = 1900
        mockHealthStore.exercise = 800
        mockHealthStore.caloriesConsumed = 2400
        let subject = WeeklyChartViewModel(healthStore: mockHealthStore)
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        let currentDate = dc.date!
        let calloutViewDetails = try await subject.calloutViewDetails(for: "Mon", currentDate: currentDate)
        XCTAssertEqual(calloutViewDetails, CallOutViewDetails(bmr: 1900,
                                                              exercise: 800,
                                                              caloriesConsumed: 2400))
        XCTAssertEqual(calloutViewDetails.difference, 300)
        XCTAssertEqual(calloutViewDetails.canEat, -200)
    }
}
