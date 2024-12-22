//
//  RecordWeightViewTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 01/08/2024.
//

import XCTest

final class RecordWeightViewTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testShowingRecordWeightScreen() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
        let recordWeightButton = app.buttons["Record weight"]
        XCTAssertTrue(recordWeightButton.exists)
        recordWeightButton.tap()
        let spinner = app.activityIndicators["Loading Weight Chart"]
        XCTAssertTrue(spinner.exists)
        XCTAssert(spinner.waitForNonExistence(timeout: 2))
        let weightHeader = app.staticTexts["Weight over time"]
        XCTAssert(weightHeader.waitForExistence(timeout: 2))
        XCTAssert(weightHeader.exists)

        let decreaseWeightButton = app.buttons["Report Decrease of 1 pound in weight"]
        decreaseWeightButton.tap()

        let newWeight = app.staticTexts["14 st, 4 lbs"]
        XCTAssert(newWeight.waitForExistence(timeout: 1))

        let applyButton = app.buttons["Apply"]
        applyButton.tap()
        sleep(1)
    }
}
