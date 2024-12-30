//
//  AddExerciseViewTests.swift
//  CaloriesUITests
//
//  Created by Tony Short on 12/08/2024.
//

import XCTest

final class AddExerciseViewTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    private func runAndReturnApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launchEnvironment["CURRENT_DATE"] = "01/01/2025"
        app.launch()
        return app
    }

    func testWhenNewExerciseIsAdded() throws
    {
        let app = runAndReturnApp()
        let addExerciseButton = app.buttons["Add exercise"]
        XCTAssertTrue(addExerciseButton.exists)
        addExerciseButton.tap()
        let searchBar = app.searchFields["Enter exercise"]
        XCTAssert(searchBar.waitForExistence(timeout: 5))
        searchBar.tap()
        searchBar.typeText("Weights")
        let addButton = app.collectionViews["Exercise List"].buttons["Add Weights as a new exercise"]
        XCTAssert(addButton.exists)
        addButton.tap()
        let caloriesTextField = app.textFields["Calories Number Field"]
        caloriesTextField.tap()
        caloriesTextField.typeText("100")

        app.buttons["Date Picker"].tap()
        app.buttons["Thursday 2 January"].tap()
        app.buttons["PopoverDismissRegion"].tap()

        let confirmationButton = app.buttons["Add Weights"]
        confirmationButton.tap()
        XCTAssertTrue(addExerciseButton.exists)
    }
}
