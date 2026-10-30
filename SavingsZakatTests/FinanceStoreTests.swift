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
        let (defaults, suiteName) = try makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let holding = Holding(id: UUID(), kind: .cash, amount: 123.45, currency: "EGP", grams: nil, carat: nil,
                              acquiredDate: date("2025-01-10"), hawlStartDate: date("2025-01-10"), purpose: .investment)
        let legacyData = try JSONEncoder().encode([holding])
        defaults.set(String(decoding: legacyData, as: UTF8.self), forKey: "testHoldingsJSON")

        let store = FinanceStore(directoryURL: directory, userDefaults: defaults)
        let migrated = try store.load()

        XCTAssertEqual(migrated.holdings, [holding])
        XCTAssertNil(defaults.object(forKey: "testHoldingsJSON"))
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

    func testInvalidLegacyJSONIsPreservedAndNotMigrated() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let (defaults, suiteName) = try makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("{invalid", forKey: "testHoldingsJSON")

        XCTAssertThrowsError(try FinanceStore(directoryURL: directory, userDefaults: defaults).load())
        XCTAssertNotNil(defaults.object(forKey: "testHoldingsJSON"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("finance-data.json").path))
    }

    func testLegacyDataRemainsWhenMigrationCannotBeWritten() throws {
        let blocker = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        defer { try? FileManager.default.removeItem(at: blocker) }
        try Data("not-a-directory".utf8).write(to: blocker)
        let (defaults, suiteName) = try makeIsolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let holding = Holding(id: UUID(), kind: .cash, amount: 10, currency: "EGP", grams: nil, carat: nil,
                              acquiredDate: date("2025-01-10"), hawlStartDate: date("2025-01-10"), purpose: .investment)
        let legacyData = try JSONEncoder().encode([holding])
        defaults.set(String(decoding: legacyData, as: UTF8.self), forKey: "testHoldingsJSON")

        XCTAssertThrowsError(try FinanceStore(directoryURL: blocker, userDefaults: defaults).load())
        XCTAssertNotNil(defaults.object(forKey: "testHoldingsJSON"))
    }


    func testRepeatedSaveLeavesCompleteLatestSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FinanceStore(directoryURL: directory)
        let firstHolding = Holding(id: UUID(), kind: .cash, amount: 10, currency: "EGP", grams: nil, carat: nil,
                                   acquiredDate: date("2025-01-10"), hawlStartDate: date("2025-01-10"), purpose: .investment)
        let latestHolding = Holding(id: UUID(), kind: .gold, amount: 20, currency: nil, grams: 20, carat: 21,
                                    acquiredDate: date("2025-02-10"), hawlStartDate: date("2025-02-10"), purpose: .investment)

        try store.save(FinanceSnapshot(holdings: [firstHolding]))
        let latestSnapshot = FinanceSnapshot(holdings: [latestHolding])
        try store.save(latestSnapshot)

        let file = directory.appendingPathComponent("finance-data.json")
        let persistedData = try Data(contentsOf: file)
        XCTAssertEqual(try JSONDecoder().decode(FinanceSnapshot.self, from: persistedData), latestSnapshot)
        XCTAssertEqual(try store.load(), latestSnapshot)
    }


    func testCreateUpdateAndDeleteChangesPersistAcrossReload() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FinanceStore(directoryURL: directory)
        let original = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 1_000)
        let removed = FinanceAccount(name: "Old wallet", kind: .wallet, currency: "EGP", openingBalance: 100)
        try store.save(FinanceSnapshot(accounts: [original, removed]))

        var updated = original
        updated.name = "Main salary account"
        updated.openingBalance = 2_500
        let added = FinanceAccount(name: "Emergency savings", kind: .savings, currency: "EGP", openingBalance: 500)
        let expected = FinanceSnapshot(accounts: [updated, added])
        try store.save(expected)

        XCTAssertEqual(try store.load(), expected)
    }

    func testCreditCardDetailsAndTransactionCategoryPersist() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FinanceStore(directoryURL: directory)
        let statement = date("2026-10-20")
        let due = date("2026-11-05")
        let card = FinanceCard(name: "Everyday credit", kind: .credit, lastFour: "4321",
                               creditLimit: 50_000, statementDate: statement,
                               paymentDueDate: due, minimumDue: 1_500)
        let transaction = FinanceTransaction(title: "Groceries", amount: 450, currency: "EGP",
                                             direction: .expense, date: statement,
                                             category: "Food")
        let snapshot = FinanceSnapshot(cards: [card], transactions: [transaction])

        try store.save(snapshot)

        XCTAssertEqual(try store.load(), snapshot)
    }

    func testOlderSnapshotDecodesWithoutOptionalCardAndCategoryFields() throws {
        let card = FinanceCard(name: "Old card", kind: .debit, lastFour: "1234")
        let transaction = FinanceTransaction(title: "Old item", amount: 10, currency: "EGP",
                                             direction: .expense, date: date("2026-01-01"))
        let encoded = try JSONEncoder().encode(FinanceSnapshot(cards: [card], transactions: [transaction]))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var cards = try XCTUnwrap(object["cards"] as? [[String: Any]])
        cards[0].removeValue(forKey: "creditLimit")
        cards[0].removeValue(forKey: "statementDate")
        cards[0].removeValue(forKey: "paymentDueDate")
        cards[0].removeValue(forKey: "minimumDue")
        object["cards"] = cards
        var transactions = try XCTUnwrap(object["transactions"] as? [[String: Any]])
        transactions[0].removeValue(forKey: "category")
        object["transactions"] = transactions
        let oldData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(FinanceSnapshot.self, from: oldData)

        XCTAssertNil(decoded.cards.first?.creditLimit)
        XCTAssertNil(decoded.cards.first?.paymentDueDate)
        XCTAssertNil(decoded.transactions.first?.category)
    }


    func testVersionOneSnapshotWithoutImportedMessageIDStillLoads() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let account = FinanceAccount(name: "Main", kind: .bank, currency: "EGP", openingBalance: 100)
        let transaction = FinanceTransaction(
            title: "Old transaction",
            amount: 10,
            currency: "EGP",
            direction: .expense,
            date: Date(),
            accountID: account.id
        )
        let encoded = try JSONEncoder().encode(FinanceSnapshot(accounts: [account], transactions: [transaction]))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var transactions = try XCTUnwrap(object["transactions"] as? [[String: Any]])
        transactions[0].removeValue(forKey: "importedMessageID")
        object["transactions"] = transactions
        let oldSchemaData = try JSONSerialization.data(withJSONObject: object)
        try oldSchemaData.write(to: directory.appendingPathComponent("finance-data.json"))

        let loaded = try FinanceStore(directoryURL: directory).load()
        XCTAssertNil(loaded.transactions.first?.importedMessageID)
        XCTAssertEqual(loaded.transactions.first?.title, "Old transaction")
    }

    private func makeIsolatedDefaults() throws -> (UserDefaults, String) {
        let suiteName = "FinanceStoreTests." + UUID().uuidString
        return (try XCTUnwrap(UserDefaults(suiteName: suiteName)), suiteName)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
