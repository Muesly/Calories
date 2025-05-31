//
//  AddFoodDetailsViewTests.swift
//  CaloriesUITests
//
//  Created by Tony Short on 19/08/2024.
//

import XCTest

final class AddFoodDetailsViewTests: XCTestCase {

    private func runAndReturnApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launchEnvironment["CURRENT_DATE"] = "01/01/2025"
        app.launch()
        return app
    }

    func testWhenNewFoodIsAdded() throws
    {
        let app = runAndReturnApp()
        goToAddFood(app)
        addNewFood(app)
        enterInDetailsOfNewFood(app)
        addPlantInNewFood(app)
        addFoodAndSeeInHistory(app)
    }

    private func goToAddFood(_ app: XCUIApplication) {
        let addFoodButton = app.buttons["Add food"]
        XCTAssertTrue(addFoodButton.exists)
        addFoodButton.tap()
    }

    private func addNewFood(_ app: XCUIApplication) {
        let foodHeader = app.staticTexts["Add new food"]
        XCTAssert(foodHeader.exists)
        let searchBar = app.searchFields.firstMatch
        XCTAssert(searchBar.exists)
        searchBar.tap()
        searchBar.typeText("Katsu Chicken & Rice")
        let addButton = app.collectionViews["Food List"].buttons["Add Katsu Chicken & Rice as a new food"]
        XCTAssert(addButton.exists)
        addButton.tap()
    }

    private func enterInDetailsOfNewFood(_ app: XCUIApplication) {
        let caloriesTextField = app.textFields["Calories Number Field"]
        caloriesTextField.tap()
        caloriesTextField.typeText("450")
        app.buttons["Lunch"].tap()

        app.buttons["Date Picker"].tap()
        app.buttons["Thursday 2 January"].tap()
        app.buttons["PopoverDismissRegion"].tap()
    }

    private func addPlantInNewFood(_ app: XCUIApplication) {
        let addPlantButton = app.buttons["Add Plant Header Button"]
        addPlantButton.tap()

        let plantSearchBar = app.searchFields["Enter Plant"]
        plantSearchBar.tap()
        plantSearchBar.typeText("Rice")

        let plantAddButton = app.collectionViews["Plant List"].buttons["Add Rice as a new plant"]
        plantAddButton.tap()
        let foodsPlantList = app.collectionViews["Food's Plant List"]
        let addedPlant = foodsPlantList.staticTexts["Rice"]
        XCTAssert(addedPlant.exists)
    }

    private func addFoodAndSeeInHistory(_ app: XCUIApplication) {
        let addButton = app.buttons["Add Katsu Chicken & Rice"]
        addButton.tap()

        let cancelSearchButton = app.buttons["Cancel"]
        cancelSearchButton.tap()

        let closeAddingFoodButton = app.buttons["Close"]
        closeAddingFoodButton.tap()

        let homeScreenScrollview = app.collectionViews.firstMatch
        homeScreenScrollview.swipeUp()

        XCTAssert(app.staticTexts["Lunch (450 cals)"].exists)
        XCTAssert(app.staticTexts["Thursday, Jan 2"].exists)
    }
}
