//
//  AddFoodDetailsViewTests.swift
//  CaloriesUITests
//
//  Created by Tony Short on 19/08/2024.
//

import XCTest

final class AddFoodDetailsViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func runAndReturnApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
        return app
    }

    func testWhenNewFoodIsAdded() throws
    {
        let app = runAndReturnApp()
        let addFoodButton = app.buttons["Add food"]
        XCTAssertTrue(addFoodButton.exists)
        addFoodButton.tap()
        let searchBar = app.searchFields["Enter Evening Snack food or drink..."]
        XCTAssert(searchBar.waitForExistence(timeout: 5))
        searchBar.tap()
        searchBar.typeText("Katsu Chicken & Rice")
        let addButton = app.collectionViews["Food List"].staticTexts["Add Katsu Chicken & Rice as a new food"]
        XCTAssert(addButton.exists)
        addButton.tap()
        let caloriesTextField = app.textFields["Calories Number Field"]
        caloriesTextField.tap()
        caloriesTextField.typeText("450")
        let confirmationButton = app.buttons["Add Katsu Chicken & Rice"]
        confirmationButton.tap()
        XCTAssertTrue(addFoodButton.exists)
    }

}
