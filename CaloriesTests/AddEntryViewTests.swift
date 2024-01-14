//
//  AddEntryViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 29/04/2023.
//

import CoreData
import SwiftUI
import ViewInspector
import XCTest

@testable import Calories

@MainActor
final class AddEntryViewTests: XCTestCase {
    var controller: PersistenceController!

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testAddingFoodEntrySuggestionUpdatesMealItems() throws {
        let addingExpectation = expectation(description: "Adding food entry")
        Task {
            let viewModel = AddEntryViewModel(healthStore: MockHealthStore(), container: controller.container)
            let date = dateFromComponents()
            try await viewModel.addFood(foodDescription: "Biscuit",
                                        calories: 60,
                                        timeConsumed: date.addingTimeInterval(-86400))
            viewModel.setDateForEntries(date)
            var showingAddEntryView = true
            let expectation = expectation(description: "Add food button tap")
            let binding = Binding(get: { showingAddEntryView }, set: { showingAddEntryView = $0 })
            let subject = AddEntryView(viewModel: viewModel,
                                       showingAddEntryView: binding,
                                       currentDate: date)
            ViewHosting.host(view: subject)
            var texts = try subject.inspect().findAll(ViewType.Text.self)
            XCTAssertEqual(try texts.map({ try $0.string() }),
                           ["Food", "Enter food or drink...", "Calories", "", "Time consumed", "Add Biscuit", "Biscuit",
                            "Recent foods you\'ve had at this time", "Morning Snack - 0 Calories", "Close"])

            let biscuitCell = try subject.inspect().find(navigationLink: "Biscuit")
            let addEntryInputFieldsView = try biscuitCell.view(AddEntryInputFieldsView.self).actualView()

            XCTAssertEqual(addEntryInputFieldsView.foodDescription, "Biscuit")
            XCTAssertEqual(addEntryInputFieldsView.calories, 60)

            let addFoodButton = try addEntryInputFieldsView.inspect().find(button: "Add Biscuit")
            try addFoodButton.tap()
            
            wait(for: [expectation], timeout: 5)

            texts = try subject.inspect().findAll(ViewType.Text.self)
            XCTAssertEqual(try! texts.map({ try $0.string() }),
                           ["Food", "Enter food or drink...", "Calories", "", "Time consumed", "Add Biscuit", "Biscuit",
                            "Recent foods you\'ve had at this time", "Morning Snack - 60 Calories", "Close"])
            addingExpectation.fulfill()
        }
        wait(for: [addingExpectation], timeout: 5)
    }
}

private extension Inspector {
    struct TestValue: Equatable {
        let value: String
    }
}
