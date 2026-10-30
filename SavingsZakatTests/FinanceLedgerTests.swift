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

        ledger.snapshot.cards.removeAll()
        try ledger.post(transaction("Lunch", 10, .expense, account: account.id))
        XCTAssertThrowsError(try ledger.removeAccount(id: account.id))
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

    private func transaction(_ title: String, _ amount: Decimal, _ direction: TransactionDirection, account: UUID) -> FinanceTransaction {
        FinanceTransaction(title: title, amount: amount, currency: "EGP", direction: direction,
                           date: today, accountID: account)
    }
}
