import XCTest
@testable import SavingsZakat

final class FinanceLedgerTests: XCTestCase {
    private let today = Date(timeIntervalSince1970: 1_760_000_000)

    func testIncomeAndExpenseChangeAccountBalance() throws {
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 1_000)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))

        try ledger.post(transaction("Salary", 500, .income, account: account.id))
        try ledger.post(transaction("Groceries", 125, .expense, account: account.id))

        XCTAssertEqual(try ledger.balance(for: account.id), 1_375)
    }

    func testOwnAccountTransferMovesBalanceWithoutChangingCombinedAssets() throws {
        let source = FinanceAccount(name: "Current", kind: .bank, currency: "EGP", openingBalance: 1_000)
        let destination = FinanceAccount(name: "Savings", kind: .savings, currency: "EGP", openingBalance: 200)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [source, destination]))

        try ledger.transfer(amount: 300, from: source.id, to: destination.id, date: today)

        XCTAssertEqual(try ledger.balance(for: source.id), 700)
        XCTAssertEqual(try ledger.balance(for: destination.id), 500)
        XCTAssertEqual(ledger.netWorth(in: "EGP", rates: [:]).totalAssets, 1_200)
        XCTAssertEqual(ledger.snapshot.transactions.first?.direction, .transfer)
    }

    func testCreditCardLiabilityReducesNetWorth() throws {
        let account = FinanceAccount(name: "Bank", kind: .bank, currency: "EGP", openingBalance: 5_000)
        let liability = FinanceLiability(name: "Credit card", kind: .creditCard, outstandingAmount: 1_250, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        try ledger.addLiability(liability)

        let result = ledger.netWorth(in: "EGP", rates: [:])
        XCTAssertEqual(result.totalAssets, 5_000)
        XCTAssertEqual(result.totalLiabilities, 1_250)
        XCTAssertEqual(result.netWorth, 3_750)
        XCTAssertFalse(result.isProvisional)
    }

    func testLoansAndInstallmentsAreIncludedAsLiabilities() throws {
        let account = FinanceAccount(name: "Cash", kind: .cash, currency: "EGP", openingBalance: 2_000)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        try ledger.addLiability(FinanceLiability(name: "Personal loan", kind: .loan, outstandingAmount: 4_000, currency: "EGP"))
        try ledger.addLiability(FinanceLiability(name: "Phone instalment", kind: .installment, outstandingAmount: 500, currency: "EGP"))

        XCTAssertEqual(ledger.netWorth(in: "EGP", rates: [:]).netWorth, -2_500)
    }

    func testCurrencyConversionAndMissingRateAreExplicitlyProvisional() throws {
        let egp = FinanceAccount(name: "EGP", kind: .bank, currency: "EGP", openingBalance: 1_000)
        let usd = FinanceAccount(name: "USD", kind: .bank, currency: "USD", openingBalance: 100)
        let ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [egp, usd]))

        let converted = ledger.netWorth(in: "EGP", rates: ["USD": 50])
        XCTAssertEqual(converted.totalAssets, 6_000)
        XCTAssertFalse(converted.isProvisional)

        let missing = ledger.netWorth(in: "EGP", rates: [:])
        XCTAssertTrue(missing.isProvisional)
        XCTAssertEqual(missing.warnings.count, 1)
    }

    func testUnreviewedTransactionCannotAffectBalance() throws {
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 100)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        let pending = FinanceTransaction(title: "Imported", amount: 50, currency: "EGP", direction: .expense,
                                         date: today, accountID: account.id, source: .shortcut, reviewStatus: .needsReview)

        XCTAssertThrowsError(try ledger.post(pending)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .transactionNeedsReview)
        }
        XCTAssertEqual(try ledger.balance(for: account.id), 100)
    }

    func testDuplicateTransactionIsRejected() throws {
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        let item = transaction("Coffee", 25, .expense, account: account.id)
        try ledger.post(item)

        XCTAssertThrowsError(try ledger.post(item)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .duplicateTransaction(item.id))
        }
    }

    func testAccountWithTransactionsOrLinkedCardsCannotBeDeleted() throws {
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP")
        let card = FinanceCard(name: "Debit", kind: .debit, lastFour: "1234", linkedAccountID: account.id)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account], cards: [card]))
        XCTAssertThrowsError(try ledger.removeAccount(id: account.id)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .accountHasActivity(account.id))
        }

        var transactionLedger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        try transactionLedger.post(transaction("Lunch", 10, .expense, account: account.id))
        XCTAssertThrowsError(try transactionLedger.removeAccount(id: account.id))
    }

    func testAccountWithoutActivityCanBeDeleted() throws {
        let account = FinanceAccount(name: "Unused", kind: .cash, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        try ledger.removeAccount(id: account.id)
        XCTAssertTrue(ledger.snapshot.accounts.isEmpty)
    }

    func testInvalidAmountsAndCurrencyMismatchAreRejected() throws {
        let egp = FinanceAccount(name: "EGP", kind: .bank, currency: "EGP")
        let usd = FinanceAccount(name: "USD", kind: .bank, currency: "USD")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [egp, usd]))

        XCTAssertThrowsError(try ledger.post(transaction("Bad", 0, .expense, account: egp.id)))
        XCTAssertThrowsError(try ledger.transfer(amount: 10, from: egp.id, to: usd.id, date: today))
    }


    func testImportedMessageCannotBePostedTwiceWithDifferentTransactionIDs() throws {
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 100)
        let importedMessageID = UUID()
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        let first = FinanceTransaction(
            title: "Purchase",
            amount: 25,
            currency: "EGP",
            direction: .expense,
            date: today,
            accountID: account.id,
            source: .shortcut,
            reviewStatus: .confirmed,
            category: "Purchase",
            importedMessageID: importedMessageID
        )
        let second = FinanceTransaction(
            title: "Purchase",
            amount: 25,
            currency: "EGP",
            direction: .expense,
            date: today,
            accountID: account.id,
            source: .shortcut,
            reviewStatus: .confirmed,
            category: "Purchase",
            importedMessageID: importedMessageID
        )

        try ledger.post(first)
        XCTAssertThrowsError(try ledger.post(second)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .duplicateImportedMessage(importedMessageID))
        }
        XCTAssertEqual(try ledger.balance(for: account.id), 75)
    }


    func testRecurringMonthlyExpenseGeneratesDueOccurrencesAndAdvancesSchedule() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 1_000)
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let rule = RecurringTransaction(title: "Rent", amount: 200, currency: "EGP", direction: .expense,
                                        accountID: account.id, category: "Housing", frequency: .monthly,
                                        nextDueDate: start)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        try ledger.addRecurringRule(rule)

        XCTAssertEqual(try ledger.generateDueRecurringTransactions(asOf: asOf, calendar: calendar), 3)
        XCTAssertEqual(try ledger.balance(for: account.id), 400)
        XCTAssertEqual(ledger.snapshot.transactions.filter { $0.recurringRuleID == rule.id }.count, 3)
        XCTAssertEqual(ledger.snapshot.recurringTransactions?.first?.nextDueDate,
                       calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)))
    }

    func testRecurringGenerationIsIdempotentWhenOccurrenceAlreadyExists() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 500)
        let due = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let rule = RecurringTransaction(title: "Internet", amount: 50, currency: "EGP", direction: .expense,
                                        accountID: account.id, frequency: .monthly, nextDueDate: due)
        let existing = FinanceTransaction(title: "Internet", amount: 50, currency: "EGP", direction: .expense,
                                          date: due, accountID: account.id, recurringRuleID: rule.id,
                                          recurrenceOccurrenceDate: due)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account], transactions: [existing],
                                                              recurringTransactions: [rule]))

        XCTAssertEqual(try ledger.generateDueRecurringTransactions(asOf: due, calendar: calendar), 0)
        XCTAssertEqual(try ledger.balance(for: account.id), 450)
        XCTAssertEqual(ledger.snapshot.transactions.count, 1)
    }

    func testRecurringRuleRejectsTransfersAndCurrencyMismatch() throws {
        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [account]))
        let transfer = RecurringTransaction(title: "Transfer", amount: 10, currency: "EGP", direction: .transfer,
                                             accountID: account.id, frequency: .weekly, nextDueDate: today)
        XCTAssertThrowsError(try ledger.addRecurringRule(transfer))
        let mismatch = RecurringTransaction(title: "USD", amount: 10, currency: "USD", direction: .expense,
                                             accountID: account.id, frequency: .weekly, nextDueDate: today)
        XCTAssertThrowsError(try ledger.addRecurringRule(mismatch))
    }


    func testCreditCardPurchaseIncreasesCardDebtWithoutChangingBankBalance() throws {
        let bank = FinanceAccount(name: "Bank", kind: .bank, currency: "EGP", openingBalance: 5_000)
        let card = FinanceCard(name: "Credit", kind: .credit, linkedAccountID: bank.id, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [bank], cards: [card]))
        let purchase = FinanceTransaction(title: "Groceries", amount: 450, currency: "EGP", direction: .expense,
                                          date: today, cardID: card.id, category: "Card purchase")
        try ledger.post(purchase)

        XCTAssertEqual(try ledger.balance(for: bank.id), 5_000)
        XCTAssertEqual(try ledger.creditCardOutstanding(for: card.id), 450)
        let summary = ledger.netWorth(in: "EGP", rates: [:])
        XCTAssertEqual(summary.totalAssets, 5_000)
        XCTAssertEqual(summary.totalLiabilities, 450)
        XCTAssertEqual(summary.netWorth, 4_550)
    }

    func testCreditCardRepaymentReducesBankAndCardDebtWithoutAddingExpense() throws {
        let bank = FinanceAccount(name: "Bank", kind: .bank, currency: "EGP", openingBalance: 5_000)
        let card = FinanceCard(name: "Credit", kind: .credit, linkedAccountID: bank.id, currency: "EGP",
                               openingOutstandingBalance: 1_000)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [bank], cards: [card]))
        let payment = FinanceTransaction(title: "Card payment", amount: 400, currency: "EGP", direction: .transfer,
                                         date: today, accountID: bank.id, destinationCardID: card.id,
                                         category: "Card repayment")
        try ledger.post(payment)

        XCTAssertEqual(try ledger.balance(for: bank.id), 4_600)
        XCTAssertEqual(try ledger.creditCardOutstanding(for: card.id), 600)
        let summary = ledger.netWorth(in: "EGP", rates: [:])
        XCTAssertEqual(summary.totalAssets, 4_600)
        XCTAssertEqual(summary.totalLiabilities, 600)
        XCTAssertEqual(summary.netWorth, 4_000)
        XCTAssertEqual(ledger.snapshot.transactions.filter { $0.direction == .expense }.count, 0)
    }

    func testLinkedOpeningCardLiabilityIsNotCountedTwice() throws {
        let bank = FinanceAccount(name: "Bank", kind: .bank, currency: "EGP", openingBalance: 2_000)
        let card = FinanceCard(name: "Credit", kind: .credit, currency: "EGP")
        let opening = FinanceLiability(name: "Old card statement", kind: .creditCard, outstandingAmount: 700,
                                       currency: "EGP", linkedCardID: card.id)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [bank], cards: [card]))
        try ledger.addLiability(opening)
        try ledger.post(FinanceTransaction(title: "Purchase", amount: 100, currency: "EGP", direction: .expense,
                                           date: today, cardID: card.id))
        XCTAssertEqual(try ledger.creditCardOutstanding(for: card.id), 800)
        XCTAssertEqual(ledger.netWorth(in: "EGP", rates: [:]).totalLiabilities, 800)
    }

    func testCreditCardPaymentCannotExceedOutstandingBalance() throws {
        let bank = FinanceAccount(name: "Bank", kind: .bank, currency: "EGP", openingBalance: 1_000)
        let card = FinanceCard(name: "Credit", kind: .credit, currency: "EGP", openingOutstandingBalance: 200)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [bank], cards: [card]))
        let payment = FinanceTransaction(title: "Overpayment", amount: 250, currency: "EGP", direction: .transfer,
                                         date: today, accountID: bank.id, destinationCardID: card.id)
        XCTAssertThrowsError(try ledger.post(payment)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .repaymentExceedsOutstanding)
        }
        XCTAssertEqual(try ledger.balance(for: bank.id), 1_000)
        XCTAssertEqual(try ledger.creditCardOutstanding(for: card.id), 200)
    }

    func testCreditCardTransactionRejectsCurrencyMismatchAndDebitCard() throws {
        let egp = FinanceAccount(name: "EGP", kind: .bank, currency: "EGP")
        let usdCard = FinanceCard(name: "USD credit", kind: .credit, currency: "USD")
        let debit = FinanceCard(name: "Debit", kind: .debit, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [egp], cards: [usdCard, debit]))
        let mismatch = FinanceTransaction(title: "Purchase", amount: 10, currency: "EGP", direction: .expense,
                                          date: today, cardID: usdCard.id)
        let debitPurchase = FinanceTransaction(title: "Purchase", amount: 10, currency: "EGP", direction: .expense,
                                               date: today, cardID: debit.id)
        XCTAssertThrowsError(try ledger.post(mismatch))
        XCTAssertThrowsError(try ledger.post(debitPurchase))
    }

    func testCardWithTransactionsCannotBeDeleted() throws {
        let card = FinanceCard(name: "Credit", kind: .credit, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(cards: [card]))
        try ledger.post(FinanceTransaction(title: "Purchase", amount: 20, currency: "EGP", direction: .expense,
                                           date: today, cardID: card.id))
        XCTAssertThrowsError(try ledger.removeCard(id: card.id)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .cardHasActivity(card.id))
        }
    }


    func testExistingStandaloneCardLiabilityCanBeLinkedWithoutChangingNetWorth() throws {
        let bank = FinanceAccount(name: "Bank", kind: .bank, currency: "EGP", openingBalance: 1_500)
        let card = FinanceCard(name: "Credit", kind: .credit, currency: "EGP")
        let oldLiability = FinanceLiability(name: "Old statement", kind: .creditCard,
                                            outstandingAmount: 650, currency: "EGP")
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(accounts: [bank], cards: [card], liabilities: [oldLiability]))
        XCTAssertEqual(ledger.netWorth(in: "EGP", rates: [:]).totalLiabilities, 650)

        try ledger.linkOpeningLiability(oldLiability.id, to: card.id)
        XCTAssertEqual(try ledger.creditCardOutstanding(for: card.id), 650)
        XCTAssertEqual(ledger.netWorth(in: "EGP", rates: [:]).totalLiabilities, 650)
        XCTAssertEqual(ledger.snapshot.liabilities.first?.linkedCardID, card.id)
    }


    func testCreditCardWithOpeningDebtCannotBeDeleted() throws {
        let card = FinanceCard(name: "Credit", kind: .credit, currency: "EGP", openingOutstandingBalance: 300)
        var ledger = FinanceLedger(snapshot: FinanceSnapshot(cards: [card]))
        XCTAssertThrowsError(try ledger.removeCard(id: card.id)) { error in
            XCTAssertEqual(error as? FinanceLedger.LedgerError, .cardHasActivity(card.id))
        }
    }

    private func transaction(_ title: String, _ amount: Decimal, _ direction: TransactionDirection, account: UUID) -> FinanceTransaction {
        FinanceTransaction(title: title, amount: amount, currency: "EGP", direction: direction,
                           date: today, accountID: account)
    }
}
