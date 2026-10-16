// BillfoldUITests.swift
// Drives the real app like a user would: add, delete, change currency, launch time.
// "UI_TESTING" gives each run a fresh in-memory store with the same sample data.

import XCTest

final class BillfoldUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        return app
    }

    /// Finds any element whose accessibility label contains `text`.
    /// Rows combine their texts into one label, so an exact match would not work.
    @MainActor
    private func element(containing text: String, in root: XCUIElement) -> XCUIElement {
        root.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
    }

    @MainActor
    func testAddExpenseByHand() {
        let app = launchApp()
        app.buttons["addExpenseButton"].tap()

        let title = app.textFields["titleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("UI Test Lunch")

        let amount = app.textFields["amountField"]
        amount.tap()
        amount.typeText("750")

        app.buttons["saveButton"].tap()
        app.tabBars.buttons["Expenses"].tap()

        XCTAssertTrue(element(containing: "UI Test Lunch", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteExpenseWithSwipe() {
        let app = launchApp()
        app.tabBars.buttons["Expenses"].tap()

        // The newest sample expense is "Keells Super", so it is the first row.
        let list = app.collectionViews.firstMatch
        let row = element(containing: "Keells Super", in: list)
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        row.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 2) {
            deleteButton.tap()
        }

        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: row)
        wait(for: [gone], timeout: 5)
    }

    @MainActor
    func testChangingCurrencyUpdatesHomeTotal() {
        let app = launchApp()
        let total = app.staticTexts["monthTotalText"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        let before = total.label

        app.buttons["settingsButton"].tap()
        let usd = app.buttons["USD"]
        XCTAssertTrue(usd.waitForExistence(timeout: 5))
        usd.tap()
        app.buttons["Done"].tap()

        let changed = expectation(for: NSPredicate(format: "label != %@", before), evaluatedWith: total)
        wait(for: [changed], timeout: 5)
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["UI_TESTING"]
            app.launch()
        }
    }
}
