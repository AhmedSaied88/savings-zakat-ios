import XCTest
@testable import SavingsZakat

final class FinanceStoreTests: XCTestCase {
    func testSaveAndLoadPreservesFinanceSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FinanceStore(directoryURL: directory)
        let account = FinanceAccount(name: "Main bank", institution: "Example Bank", kind: .bank, currency: "EGP", openingBalance: 1_250)
        let card = FinanceCard(name: "Debit", issuer: "Example Bank", kind: .debit, lastFour: "1234", linkedAccountID: account.id)
        let transaction = FinanceTransaction(title: "Groceries", amount: 250, currency: "EGP", direction: .expense, date: Date(), accountID: account.id, source: .manual, reviewStatus: .confirmed)
        let liability = FinanceLiability(name: "Installment", kind: .installment, outstandingAmount: 2_000, currency: "EGP")
        let snapshot = FinanceSnapshot(accounts: [account], cards: [card], transactions: [transaction], liabilities: [liability])

        try store.save(snapshot)
        XCTAssertEqual(try store.load(), snapshot)
    }

    func testMissingStoreLoadsAnEmptySnapshot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertEqual(try FinanceStore(directoryURL: directory).load(), FinanceSnapshot())
    }

    func testCardModelKeepsOnlyLastFourDigits() {
        let card = FinanceCard(name: "Credit", issuer: "Example", kind: .credit, lastFour: "9876")
        XCTAssertEqual(card.lastFour, "9876")
    }
}
