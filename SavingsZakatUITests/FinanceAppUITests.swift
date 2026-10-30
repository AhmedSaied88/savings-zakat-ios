import XCTest

final class FinanceAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryTabsAndCreateAccountAndCategorizedTransaction() throws {
        let app = launchCleanApp()

        for tab in ["Wallet", "Accounts", "Activity", "Debts", "Zakat"] {
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 5), "Missing tab: \(tab)")
        }

        app.tabBars.buttons["Accounts"].tap()
        app.buttons["Add account"].tap()

        let accountName = app.textFields["Account name"]
        XCTAssertTrue(accountName.waitForExistence(timeout: 3))
        accountName.tap()
        accountName.typeText("UI Test Main")
        app.buttons["Save"].tap()

        let accountRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "UI Test Main")
        ).firstMatch
        XCTAssertTrue(accountRow.waitForExistence(timeout: 5))

        app.tabBars.buttons["Activity"].tap()
        app.buttons["Add transaction"].tap()

        let description = app.textFields["Description"]
        XCTAssertTrue(description.waitForExistence(timeout: 3))
        description.tap()
        description.typeText("UI test groceries")

        let amount = app.textFields["Amount"]
        amount.tap()
        amount.typeText("50")

        app.buttons["Save"].tap()

        let categorizedTransaction = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Shopping")
        ).firstMatch
        XCTAssertTrue(categorizedTransaction.waitForExistence(timeout: 5))
    }

    func testCardEntryMasksDigitsToLastFour() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Accounts"].tap()
        app.buttons["Add card"].tap()

        let cardName = app.textFields["Card label"]
        XCTAssertTrue(cardName.waitForExistence(timeout: 3))
        cardName.tap()
        cardName.typeText("Test debit")

        let lastFour = app.textFields["Last four digits only"]
        lastFour.tap()
        lastFour.typeText("123456")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["•••• 3456"].waitForExistence(timeout: 5))
    }

    func testCreditCardEntryShowsPaymentDueDate() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Accounts"].tap()
        app.buttons["Add card"].tap()

        let cardName = app.textFields["Card label"]
        XCTAssertTrue(cardName.waitForExistence(timeout: 3))
        cardName.tap()
        cardName.typeText("UI Test Credit")

        let debitPicker = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Debit")
        ).firstMatch
        XCTAssertTrue(debitPicker.waitForExistence(timeout: 3))
        debitPicker.tap()
        app.buttons["Credit"].tap()

        let limit = app.textFields["Credit limit (optional)"]
        XCTAssertTrue(limit.waitForExistence(timeout: 3))
        limit.tap()
        limit.typeText("50000")

        let minimum = app.textFields["Minimum payment (optional)"]
        minimum.tap()
        minimum.typeText("1500")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Payment due")
        ).firstMatch.waitForExistence(timeout: 5))
    }

    private func launchCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
        app.launch()
        return app
    }
}
