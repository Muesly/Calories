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

    func testSpinnerShownWhenLoadingWeightChart() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
        let recordWeightButton = app.buttons["Record weight"]
        XCTAssertTrue(recordWeightButton.exists)
        recordWeightButton.tap()
        let spinner = app.activityIndicators["Loading Weight Chart"]
        XCTAssertTrue(spinner.exists)
    }
}
