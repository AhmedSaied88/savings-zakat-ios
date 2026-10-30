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

        app.tabBars.buttons["Wallet"].tap()
        XCTAssertTrue(app.staticTexts["UI Test Main"].waitForExistence(timeout: 5))

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
        let addCard = app.buttons["Add card"]
        XCTAssertTrue(scrollTo(addCard, in: app), "Add card should be reachable by scrolling the Accounts list")
        addCard.tap()

        let cardName = app.textFields["Card label"]
        XCTAssertTrue(cardName.waitForExistence(timeout: 3))
        cardName.tap()
        cardName.typeText("Test debit")

        let lastFour = app.textFields["Last four digits only"]
        lastFour.tap()
        lastFour.typeText("123456")

        app.buttons["Save"].tap()

        let maskedDigits = app.staticTexts["card-last-four"]
        XCTAssertTrue(maskedDigits.waitForExistence(timeout: 5))
        XCTAssertEqual(maskedDigits.label, "•••• 3456")
    }

    func testCreditCardEntryShowsPaymentDueDate() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Accounts"].tap()
        let addCard = app.buttons["Add card"]
        XCTAssertTrue(scrollTo(addCard, in: app), "Add card should be reachable by scrolling the Accounts list")
        addCard.tap()

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

        let insights = app.buttons["Monthly income & expenses"]
        XCTAssertTrue(scrollTo(insights, in: app), "Monthly insights link should be reachable from Wallet")
        insights.tap()
        XCTAssertTrue(app.navigationBars["Monthly insights"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let settings = app.buttons["Settings & backup"]
        XCTAssertTrue(scrollTo(settings, in: app), "Settings link should be reachable from Wallet")
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Valuation, parser & calendar"].tap()
        XCTAssertTrue(app.navigationBars["Finance preferences"].waitForExistence(timeout: 5))
    }

    func testCanCreateCustomBankParserRule() throws {
        let app = launchCleanApp()
        let settings = app.buttons["Settings & backup"]
        XCTAssertTrue(scrollTo(settings, in: app))
        settings.tap()
        let preferences = app.buttons["Valuation, parser & calendar"]
        XCTAssertTrue(scrollTo(preferences, in: app))
        preferences.tap()
        let addRule = app.buttons["add-custom-bank-rule"]
        XCTAssertTrue(scrollTo(addRule, in: app))
        addRule.tap()

        let keyword = app.textFields["Keyword or phrase"]
        XCTAssertTrue(keyword.waitForExistence(timeout: 3))
        keyword.tap()
        keyword.typeText("marketplace")

        let category = app.textFields["Transaction category"]
        category.tap()
        category.typeText("Online shopping")

        app.buttons["Save"].tap()
        let savedRule = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "marketplace", "Online shopping")
        ).firstMatch
        XCTAssertTrue(savedRule.waitForExistence(timeout: 5), "Saved parser rule should expose its keyword and category")
    }

    func testBackupScreenRequiresPassphraseConfirmation() throws {
        let app = launchCleanApp()
        let settings = app.buttons["Settings & backup"]
        XCTAssertTrue(scrollTo(settings, in: app))
        settings.tap()
        let backup = app.buttons["Backup & Restore"]
        XCTAssertTrue(scrollTo(backup, in: app))
        backup.tap()

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
        let settings = app.buttons["Settings & backup"]
        XCTAssertTrue(scrollTo(settings, in: app), "Settings should remain reachable at accessibility text sizes")
    }


    func testWalletDisplaysEmptyAccountsState() throws {
        let app = launchCleanApp()
        XCTAssertTrue(app.staticTexts["No accounts yet"].waitForExistence(timeout: 5))
    }

    func testHawlCalendarDisplaysEmptyStateWithoutRequestingReminders() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Zakat"].tap()
        let hawlCalendar = app.buttons["View Hawl calendar and reminders"]
        XCTAssertTrue(scrollTo(hawlCalendar, in: app), "Hawl calendar link should be reachable by scrolling the Zakat list")
        hawlCalendar.tap()
        XCTAssertTrue(app.staticTexts["No Hawl dates"].waitForExistence(timeout: 5))
        let scheduleButton = app.buttons["Schedule / refresh reminders"]
        XCTAssertTrue(scheduleButton.waitForExistence(timeout: 3), "Reminder scheduling control should remain discoverable when disabled")
        XCTAssertFalse(scheduleButton.isEnabled, "Reminder scheduling should be disabled until an asset has a Hawl date")
        XCTAssertFalse(app.staticTexts["Notifications are not permitted."].exists)
    }

    func testZakatCalculationControlsRemainVisible() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Zakat"].tap()
        let calculateButton = app.buttons["Calculate Zakat"]
        XCTAssertTrue(scrollTo(calculateButton, in: app), "Zakat calculation should be reachable by scrolling the Zakat list")
        XCTAssertTrue(calculateButton.isHittable)
        let nisabLabel = app.staticTexts["Nisab (EGP)"]
        XCTAssertTrue(nisabLabel.exists && nisabLabel.isHittable)
        let personalGoldToggle = app.switches["Include personal-use gold"]
        XCTAssertTrue(personalGoldToggle.exists && personalGoldToggle.isHittable)
        calculateButton.tap()
        XCTAssertTrue(app.staticTexts["Total valued assets"].waitForExistence(timeout: 5))
    }

    @discardableResult
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 10) -> Bool {
        let scrollView = app.scrollViews.firstMatch
        let table = app.tables.firstMatch
        let collection = app.collectionViews.firstMatch
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return true }
            if scrollView.exists {
                scrollView.swipeUp()
            } else if table.exists {
                table.swipeUp()
            } else if collection.exists {
                collection.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        return element.exists && element.isHittable
    }

    private func launchCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
        app.launch()
        return app
    }
}
