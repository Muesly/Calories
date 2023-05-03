//
//  AddEntryInputFieldsViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 02/05/2023.
//

import CoreData
import SwiftUI
import ViewInspector
import XCTest

@testable import Calories

final class AddEntryInputFieldsViewTests: XCTestCase {
    var controller: PersistenceController!

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
    }

    func dateFromComponents() -> Date {
        let dc = DateComponents(calendar: Calendar.current, year: 2023, month: 1, day: 1, hour: 11, minute: 30)
        return dc.date!
    }

    func testAddingFoodEntrySuggestionUpdatesMealItems() throws {
        let viewModel = AddEntryViewModel(healthStore: MockHealthStore(), container: controller.container)
        let date = dateFromComponents()
        viewModel.setDateForEntries(date)

        let expectation = expectation(description: "Add food button tap")
        let timeConsumedBinding = Binding<Date>(wrappedValue: date)
        let foodAddedBinding = Binding<Bool>(wrappedValue: false)
        var searchText = "Biscuit"
        let searchTextBinding = Binding(get: { searchText }, set: {
            searchText = $0
            expectation.fulfill()
        })

        let subject = AddEntryInputFieldsView(viewModel: viewModel,
                                              defFoodDescription: "Biscuit",
                                              defCalories: 60,
                                              defTimeConsumed: timeConsumedBinding,
                                              searchText: searchTextBinding,
                                              foodAdded: foodAddedBinding)
        XCTAssertEqual(subject.foodDescription, "Biscuit")
        XCTAssertEqual(subject.calories, 60)

        XCTAssertFalse(foodAddedBinding.wrappedValue)

        let addFoodButton = try subject.inspect().find(button: "Add Biscuit")
        try addFoodButton.tap()

        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(foodAddedBinding.wrappedValue)
    }
}
