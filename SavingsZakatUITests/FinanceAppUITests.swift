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

        let cardTypePicker = app.descendants(matching: .any)["card-kind-picker"]
        XCTAssertTrue(cardTypePicker.waitForExistence(timeout: 3))
        cardTypePicker.tap()
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


    func testWalletInsightsAndSettingsNavigation() throws {
        let app = launchCleanApp()

        app.buttons["Monthly income & expenses"].tap()
        XCTAssertTrue(app.navigationBars["Monthly insights"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["Settings & backup"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Valuation, parser & calendar"].tap()
        XCTAssertTrue(app.navigationBars["Finance preferences"].waitForExistence(timeout: 5))
    }

    func testCanCreateCustomBankParserRule() throws {
        let app = launchCleanApp()
        app.buttons["Settings & backup"].tap()
        app.buttons["Valuation, parser & calendar"].tap()
        app.buttons["Add custom keyword rule"].tap()

        let keyword = app.textFields["Keyword or phrase"]
        XCTAssertTrue(keyword.waitForExistence(timeout: 3))
        keyword.tap()
        keyword.typeText("marketplace")

        let category = app.textFields["Transaction category"]
        category.tap()
        category.typeText("Online shopping")

        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["marketplace"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Online shopping"].exists)
    }

    func testBackupScreenRequiresPassphraseConfirmation() throws {
        let app = launchCleanApp()
        app.buttons["Settings & backup"].tap()
        app.buttons["Backup & Restore"].tap()

        let passphrase = app.secureTextFields["Backup passphrase"]
        XCTAssertTrue(passphrase.waitForExistence(timeout: 3))
        passphrase.tap()
        passphrase.typeText("correct horse battery staple")

        let confirmation = app.secureTextFields["Confirm passphrase"]
        confirmation.tap()
        confirmation.typeText("correct horse battery staple")

        XCTAssertTrue(app.buttons["Export encrypted backup"].isEnabled)
        XCTAssertTrue(app.buttons["Choose backup file"].isEnabled)
    }

    func testPrimaryNavigationRemainsAvailableAtAccessibilityTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-reset",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        for tab in ["Wallet", "Accounts", "Activity", "Debts", "Zakat"] {
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 5), "Missing tab at large text size: \(tab)")
        }
        XCTAssertTrue(app.buttons["Settings & backup"].exists)
    }

    private func launchCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
        app.launch()
        return app
    }
}
