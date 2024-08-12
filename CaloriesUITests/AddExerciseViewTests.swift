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
        searchBar.tap()
        searchBar.typeText("Weights")
        let addButton = app.collectionViews["Exercise List"].staticTexts["Add Weights as a new exercise"]
        XCTAssert(addButton.exists)
        addButton.tap()
        XCTAssert(app.staticTexts["Screen to add details on new exercise"].exists)
    }

    func testWhenPreviousExerciseItIsShownAsOptionWhenNewExerciseAdded() throws {
        let app = runAndReturnApp()
        let addExerciseButton = app.buttons["Add exercise"]
        XCTAssertTrue(addExerciseButton.exists)
        addExerciseButton.tap()
        let addNewExerciseTitle = app.navigationBars.staticTexts["Add new exercise"]
        XCTAssertTrue(addNewExerciseTitle.exists)
        let previousSwimmingExerciseEntry = app.staticTexts["Swimming"]
        XCTAssertTrue(previousSwimmingExerciseEntry.exists)
    }
}
