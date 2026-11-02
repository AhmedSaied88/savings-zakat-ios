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
        XCTAssertTrue(scrollTo(categorizedTransaction, in: app),
                      "The saved transaction should show its Shopping category in Activity")
        let directionLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "Expense")
        ).firstMatch
        XCTAssertTrue(scrollTo(directionLabel, in: app),
                      "Transaction direction must be visible as text, not communicated by icon color alone")
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
        lastFour.typeText("3456")
        let enteredDigits = NSPredicate(format: "value == %@", "3456")
        expectation(for: enteredDigits, evaluatedWith: lastFour)
        waitForExpectations(timeout: 5)

        app.buttons["Save"].tap()

        let maskedDigits = app.staticTexts["card-last-four"]
        XCTAssertTrue(maskedDigits.waitForExistence(timeout: 5))
        XCTAssertEqual(maskedDigits.label, "•••• 3456")
        let cardRow = app.buttons["card-row-Test debit"]
        XCTAssertTrue(cardRow.waitForExistence(timeout: 5))
        XCTAssertTrue(cardRow.label.contains("Card ending in 3456"),
                      "VoiceOver should announce only the stored last four digits")
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

        // Dismiss the decimal keyboard before interacting with the lower Form control.
        app.navigationBars["New card"].tap()

        // The Form lazily exposes lower controls; scroll the form before querying the switch.
        for _ in 0..<4 {
            app.swipeUp()
            if app.switches["card-payment-due-date-toggle"].exists { break }
        }
        let dueDateToggle = app.switches["card-payment-due-date-toggle"]
        XCTAssertTrue(dueDateToggle.waitForExistence(timeout: 5),
                      "The due-date toggle should appear after scrolling the credit-card form")
        XCTAssertTrue(dueDateToggle.isHittable,
                      "The due-date toggle should be hittable after scrolling")
        if dueDateToggle.value as? String != "1" {
            // The switch is trailing-aligned in the Form row. Tap its control area,
            // not the center of the full accessibility frame (which can hit the label).
            dueDateToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        let dueDateEnabled = NSPredicate(format: "value == %@", "1")
        expectation(for: dueDateEnabled, evaluatedWith: dueDateToggle)
        waitForExpectations(timeout: 3)
        XCTAssertEqual(dueDateToggle.value as? String, "1",
                       "The payment due-date option should be enabled before saving")
        let dueDatePicker = app.descendants(matching: .any)["card-payment-due-date-picker"]
        XCTAssertTrue(dueDatePicker.waitForExistence(timeout: 3),
                      "Enabling the due-date option should reveal its date picker")

        app.buttons["Save"].tap()

        let creditCardRow = app.buttons["card-row-UI Test Credit"]
        XCTAssertTrue(scrollTo(creditCardRow, in: app),
                      "The saved credit card row should be accessible")
        XCTAssertTrue(creditCardRow.label.contains("Credit"),
                      "The saved card should retain its credit-card type")
        XCTAssertTrue(creditCardRow.label.contains("Payment due"),
                      "The accessible credit card row should include its payment due-date description")
    }


    func testWalletInsightsAndSettingsNavigation() throws {
        let app = launchCleanApp()

        let insights = app.buttons["Monthly income & expenses"]
        XCTAssertTrue(scrollTo(insights, in: app), "Monthly insights link should be reachable from Wallet")
        insights.tap()
        XCTAssertTrue(app.navigationBars["Monthly insights"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let settings = app.descendants(matching: .any)["wallet-settings-link"]
        XCTAssertTrue(scrollTo(settings, in: app), "Settings link should be reachable from Wallet")
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8),
                      "Settings destination should finish presenting")
        let preferencesLink = app.buttons["Valuation, parser & calendar"]
        XCTAssertTrue(preferencesLink.waitForExistence(timeout: 5),
                      "Finance preferences link should be available in Settings")
        preferencesLink.tap()
        XCTAssertTrue(app.navigationBars["Finance preferences"].waitForExistence(timeout: 5))
    }

    func testCanCreateCustomBankParserRule() throws {
        let app = launchCleanApp()
        let settings = app.buttons["Settings & backup"]
        XCTAssertTrue(scrollTo(settings, in: app))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8),
                      "Settings destination should finish presenting")
        let preferences = app.buttons["Valuation, parser & calendar"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 5),
                      "Finance preferences link should be available in Settings")
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
        let savedRule = app.buttons.matching(identifier: "custom-bank-rule-row").firstMatch
        XCTAssertTrue(scrollTo(savedRule, in: app), "Saved parser rule should be reachable")
        XCTAssertTrue(savedRule.waitForExistence(timeout: 5), "Saved parser rule should be discoverable")
        XCTAssertTrue(savedRule.label.contains("marketplace"), "Saved parser rule should expose its keyword")
        XCTAssertTrue(savedRule.label.contains("Online shopping"), "Saved parser rule should expose its category")
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
        XCTAssertTrue(scrollTo(settings, in: app, maxSwipes: 20), "Settings should remain reachable at accessibility text sizes")
    }


    func testWalletRendersInDarkAppearance() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-reset",
            "-uiUserInterfaceStyle",
            "dark"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Wallet"].waitForExistence(timeout: 5))
        let quickAdd = app.descendants(matching: .any)
            .matching(identifier: "wallet-quick-add")
            .firstMatch
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 5))
        XCTAssertTrue(quickAdd.isHittable)
    }

    func testWalletQuickAddMenuOpensAccountEditor() throws {
        let app = launchCleanApp()
        let quickAdd = app.descendants(matching: .any)
            .matching(identifier: "wallet-quick-add")
            .firstMatch
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 5), "Quick-add control should be exposed to accessibility")
        XCTAssertTrue(quickAdd.isHittable, "Quick-add control should be tappable")
        quickAdd.tap()

        let accountAction = app.buttons["wallet-quick-add-account"]
        XCTAssertTrue(accountAction.waitForExistence(timeout: 3))
        accountAction.tap()

        XCTAssertTrue(app.navigationBars["Add account"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Account name"].exists)
    }

    func testWalletDisplaysEmptyAccountsState() throws {
        let app = launchCleanApp()
        XCTAssertTrue(app.staticTexts["No accounts yet"].waitForExistence(timeout: 5))
    }

    func testHawlCalendarDisplaysEmptyStateWithoutRequestingReminders() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Zakat"].tap()
        let hawlCalendar = app.descendants(matching: .any)["hawl-calendar-link"]
        XCTAssertTrue(scrollTo(hawlCalendar, in: app, maxSwipes: 20),
                      "Hawl calendar link should be reachable by scrolling the Zakat list")
        hawlCalendar.tap()
        XCTAssertTrue(app.staticTexts["No Hawl dates"].waitForExistence(timeout: 5))
        let scheduleButton = app.buttons["schedule-hawl-reminders"]
        XCTAssertTrue(scrollTo(scheduleButton, in: app), "Reminder scheduling control should be reachable")
        XCTAssertTrue(scheduleButton.waitForExistence(timeout: 3), "Reminder scheduling control should remain discoverable when disabled")
        XCTAssertFalse(scheduleButton.isEnabled, "Reminder scheduling should be disabled until an asset has a Hawl date")
        XCTAssertFalse(app.staticTexts["Notifications are not permitted."].exists)
    }

    func testZakatAssetEntryTilesAreAccessible() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Zakat"].tap()

        for assetType in ["cash", "gold", "silver", "investment"] {
            let tile = app.buttons["add-asset-\(assetType)"]
            XCTAssertTrue(scrollTo(tile, in: app, maxSwipes: 20),
                          "The \(assetType) asset entry tile should be reachable")
            XCTAssertTrue(tile.label.localizedCaseInsensitiveContains(assetType),
                          "The \(assetType) tile should have a meaningful accessible name")
        }
    }

    func testZakatCalculationControlsRemainVisible() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Zakat"].tap()
        let calculateButton = app.buttons["zakat-calculate-button"]
        XCTAssertTrue(scrollTo(calculateButton, in: app, maxSwipes: 20),
                      "Zakat calculation should be reachable by scrolling the Zakat list")
        XCTAssertTrue(calculateButton.isHittable)
        let nisabLabel = app.staticTexts["Nisab (EGP)"]
        XCTAssertTrue(scrollTo(nisabLabel, in: app, maxSwipes: 20),
                      "Nisab input should be reachable by scrolling the Zakat list")
        XCTAssertTrue(nisabLabel.isHittable)
        let personalGoldToggle = app.switches["Include personal-use gold"]
        XCTAssertTrue(scrollTo(personalGoldToggle, in: app, maxSwipes: 20),
                      "Personal-use gold setting should be reachable by scrolling the Zakat list")
        XCTAssertTrue(personalGoldToggle.isHittable)
        calculateButton.tap()
        XCTAssertTrue(app.staticTexts["Total valued assets"].waitForExistence(timeout: 5))
    }


    func testCanCreateRecurringExpenseRule() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Accounts"].tap()
        app.buttons["Add account"].tap()
        let accountName = app.textFields["Account name"]
        XCTAssertTrue(accountName.waitForExistence(timeout: 3))
        accountName.tap()
        accountName.typeText("Recurring Test Account")
        app.buttons["Save"].tap()

        app.tabBars.buttons["Activity"].tap()
        let addRecurring = app.buttons["add-recurring-transaction"]
        XCTAssertTrue(scrollTo(addRecurring, in: app), "Recurring transaction action should be reachable")
        addRecurring.tap()

        let description = app.textFields["Description"]
        XCTAssertTrue(description.waitForExistence(timeout: 3))
        description.tap()
        description.typeText("Monthly rent")
        let amount = app.textFields["Amount"]
        amount.tap()
        amount.typeText("2500")

        app.buttons["Save"].tap()
        let savedRule = app.staticTexts["Monthly rent"]
        XCTAssertTrue(savedRule.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "monthly")
        ).firstMatch.exists)
    }


    func testCreditCardPurchaseAndRepaymentReconcileBalances() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Accounts"].tap()
        app.buttons["Add account"].tap()

        let accountName = app.textFields["Account name"]
        XCTAssertTrue(accountName.waitForExistence(timeout: 3))
        accountName.tap()
        accountName.typeText("UI Test Bank")
        let openingBalance = app.textFields["Opening balance"]
        openingBalance.tap()
        openingBalance.typeText("1000")
        app.buttons["Save"].tap()

        let addCard = app.buttons["Add card"]
        XCTAssertTrue(scrollTo(addCard, in: app))
        addCard.tap()
        let cardName = app.textFields["Card label"]
        XCTAssertTrue(cardName.waitForExistence(timeout: 3))
        cardName.tap()
        cardName.typeText("UI Test Credit")
        let cardKind = app.descendants(matching: .any)["card-kind-picker"]
        cardKind.tap()
        app.buttons["Credit"].tap()

        let linkedAccount = app.descendants(matching: .any)["Linked account"]
        XCTAssertTrue(linkedAccount.waitForExistence(timeout: 3))
        linkedAccount.tap()
        app.buttons["UI Test Bank"].tap()

        let openingCardBalance = app.textFields["Current outstanding balance"]
        XCTAssertTrue(openingCardBalance.waitForExistence(timeout: 3))
        openingCardBalance.tap()
        openingCardBalance.typeText("200")
        app.buttons["Save"].tap()

        app.tabBars.buttons["Activity"].tap()
        app.buttons["Add transaction"].tap()
        let entryType = app.descendants(matching: .any)["Entry type"]
        XCTAssertTrue(entryType.waitForExistence(timeout: 3))
        entryType.tap()
        app.buttons["Credit-card purchase"].tap()

        let description = app.textFields["Description"]
        description.tap()
        description.typeText("Card groceries")
        let amount = app.textFields["Amount"]
        amount.tap()
        amount.typeText("100")
        app.buttons["Save"].tap()

        app.buttons["Add transaction"].tap()
        let secondEntryType = app.descendants(matching: .any)["Entry type"]
        secondEntryType.tap()
        app.buttons["Credit-card repayment"].tap()
        let repaymentDescription = app.textFields["Description"]
        repaymentDescription.tap()
        repaymentDescription.typeText("Card repayment")
        let repaymentAmount = app.textFields["Amount"]
        repaymentAmount.tap()
        repaymentAmount.typeText("50")
        app.buttons["Save"].tap()

        app.tabBars.buttons["Accounts"].tap()
        let bankBalance = app.staticTexts["account-balance-UI Test Bank"]
        XCTAssertTrue(scrollTo(bankBalance, in: app))
        XCTAssertTrue(bankBalance.label.contains("950"), "Repayment should reduce the bank account by 50")

        app.tabBars.buttons["Debts"].tap()
        let cardBalance = app.staticTexts["debt-card-outstanding-UI Test Credit"]
        XCTAssertTrue(cardBalance.waitForExistence(timeout: 5))
        XCTAssertTrue(cardBalance.label.contains("250"), "Card balance should be opening 200 + purchase 100 - repayment 50")
    }

    func testFinancePreferencesExplainEgyptianAstronomicalEstimate() throws {
        let app = launchCleanApp()
        let settings = app.buttons["Settings & backup"]
        XCTAssertTrue(scrollTo(settings, in: app))
        settings.tap()

        let preferences = app.buttons["Valuation, parser & calendar"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 5))
        preferences.tap()

        let estimateDescription = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "Cairo astronomical estimate")
        ).firstMatch
        XCTAssertTrue(scrollTo(estimateDescription, in: app, maxSwipes: 20),
                      "Settings must explain the Egypt-calibrated astronomical estimate")
        XCTAssertTrue(estimateDescription.label.contains("Estimated"),
                      "Calculated Hijri dates must remain explicitly estimated")
        XCTAssertFalse(estimateDescription.label.localizedCaseInsensitiveContains("Islamic-civil fallback only"),
                       "Settings must not describe the superseded civil-only fallback")
    }

    func testZakatShowsBothMethodsAndSavesTheSelectedSnapshot() throws {
        let app = launchCleanApp()
        app.tabBars.buttons["Zakat"].tap()

        let calculate = app.buttons["zakat-calculate-button"]
        XCTAssertTrue(scrollTo(calculate, in: app, maxSwipes: 20))
        calculate.tap()

        let independentMethod = app.buttons["zakat-method-independentCategories"]
        XCTAssertTrue(scrollTo(independentMethod, in: app, maxSwipes: 20))
        independentMethod.tap()

        let saveSelected = app.buttons["zakat-save-selected-result"]
        XCTAssertTrue(scrollTo(saveSelected, in: app, maxSwipes: 20))
        saveSelected.tap()

        let savedHeading = app.staticTexts["Saved calculation snapshot"]
        XCTAssertTrue(scrollTo(savedHeading, in: app, maxSwipes: 20))
        XCTAssertTrue(savedHeading.exists)
    }

    func testCapturePrimaryTabsForVisualReview() throws {
        let app = launchCleanApp(contentSizeCategory: "UICTContentSizeCategoryLarge", populated: true)
        let tabs = ["Wallet", "Accounts", "Activity", "Debts", "Zakat"]

        for (index, tab) in tabs.enumerated() {
            let tabButton = app.tabBars.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 5), "Missing tab for visual review: \(tab)")
            if index > 0 {
                tabButton.tap()
            }
            XCTAssertTrue(app.tabBars.buttons[tab].exists, "Tab should remain present after navigation: \(tab)")
            attachVisualReviewScreenshot("Visual Review - \(tab)", from: app)
            if tab == "Zakat" {
                let calculate = app.buttons["zakat-calculate-button"]
                XCTAssertTrue(scrollTo(calculate, in: app, maxSwipes: 20))
                calculate.tap()
                attachVisualReviewScreenshot("Visual Review - Zakat Calculation", from: app)
            }
        }
    }

    private func attachVisualReviewScreenshot(_ name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @discardableResult
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 10) -> Bool {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.88))
        let finish = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return true }
            // Start the gesture in the lower content viewport, clear of the tab
            // bar and row controls. XCUIApplication.swipeUp() can start over a
            // control and fail to advance a SwiftUI List to its next lazy row.
            start.press(forDuration: 0.05, thenDragTo: finish)
        }
        return element.exists && element.isHittable
    }

    private func launchCleanApp(contentSizeCategory: String? = nil, populated: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
        if populated { app.launchArguments.append("-ui-testing-populated") }
        if let contentSizeCategory {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSizeCategory]
        }
        app.launch()
        return app
    }
}
