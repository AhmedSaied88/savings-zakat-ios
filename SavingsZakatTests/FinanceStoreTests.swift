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

    func testMigratesLegacyPrototypeHoldingsJSONOnFirstLoad() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let key = "testHoldingsJSON"
        let defaults = UserDefaults.standard
        let previousValue = defaults.object(forKey: key)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        let holding = Holding(
            id: UUID(),
            kind: .cash,
            amount: 123.45,
            currency: "EGP",
            grams: nil,
            carat: nil,
            acquiredDate: date("2025-01-10"),
            hawlStartDate: date("2025-01-10"),
            purpose: .investment
        )
        let legacyData = try JSONEncoder().encode([holding])
        defaults.set(String(decoding: legacyData, as: UTF8.self), forKey: key)

        let store = FinanceStore(directoryURL: directory)
        let migrated = try store.load()

        XCTAssertEqual(migrated.holdings, [holding])
        XCTAssertNil(defaults.object(forKey: key))
        XCTAssertEqual(try store.load(), migrated)
    }

    func testCorruptSnapshotIsNotOverwrittenDuringLoad() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("finance-data.json")
        let corruptData = Data("{invalid-json".utf8)
        try corruptData.write(to: file)

        XCTAssertThrowsError(try FinanceStore(directoryURL: directory).load())
        XCTAssertEqual(try Data(contentsOf: file), corruptData)
    }

    func testUnsupportedSchemaVersionIsRejectedWithoutChangingFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("finance-data.json")
        let unsupportedData = try JSONEncoder().encode(FinanceSnapshot(schemaVersion: 99))
        try unsupportedData.write(to: file)

        XCTAssertThrowsError(try FinanceStore(directoryURL: directory).load()) { error in
            XCTAssertEqual(error as? FinanceStore.StoreError, .unsupportedSchemaVersion(99))
        }
        XCTAssertEqual(try Data(contentsOf: file), unsupportedData)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
