import XCTest
@testable import SavingsZakat

final class BackupServiceTests: XCTestCase {
    private let passphrase = "correct horse battery staple"

    func testEncryptedBackupRoundTripsFinanceSnapshot() throws {
        let account = FinanceAccount(name: "Main bank", kind: .bank, currency: "EGP", openingBalance: 12_500)
        let holding = Holding(
            id: UUID(), kind: .gold, amount: 8, currency: nil, grams: 8, carat: 21,
            acquiredDate: date("2025-01-01"), hawlStartDate: date("2025-01-01"),
            purpose: .investment
        )
        let transaction = FinanceTransaction(
            title: "Groceries", amount: 500, currency: "EGP", direction: .expense,
            date: date("2026-10-01"), accountID: account.id, reviewStatus: .confirmed
        )
        let snapshot = FinanceSnapshot(accounts: [account], transactions: [transaction], holdings: [holding])
        let service = BackupService()

        let archive = try service.exportBackup(snapshot: snapshot, passphrase: passphrase)
        let restored = try service.importBackup(data: archive, passphrase: passphrase)

        XCTAssertEqual(restored, snapshot)
        XCTAssertFalse(String(decoding: archive, as: UTF8.self).contains("Main bank"))
        XCTAssertFalse(String(decoding: archive, as: UTF8.self).contains("Groceries"))
    }

    func testWrongPassphraseFailsAuthentication() throws {
        let service = BackupService()
        let archive = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)

        XCTAssertThrowsError(try service.importBackup(data: archive, passphrase: "different strong passphrase")) {
            XCTAssertEqual($0 as? BackupService.BackupError, .authenticationFailed)
        }
    }

    func testMalformedArchiveIsRejected() {
        XCTAssertThrowsError(try BackupService().importBackup(
            data: Data("not a backup".utf8),
            passphrase: passphrase
        )) {
            XCTAssertEqual($0 as? BackupService.BackupError, .invalidArchive)
        }
    }

    func testUnsupportedBackupVersionIsRejectedBeforeDecryption() throws {
        let service = BackupService()
        let archive = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)
        let changed = try archiveObject(archive, changing: "backupVersion", to: 99)
        let data = try JSONSerialization.data(withJSONObject: changed)

        XCTAssertThrowsError(try service.importBackup(data: data, passphrase: passphrase)) {
            XCTAssertEqual($0 as? BackupService.BackupError, .unsupportedBackupVersion(99))
        }
    }

    func testUnsafeKDFParametersAreRejectedBeforeKeyDerivation() throws {
        let service = BackupService()
        let archive = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)
        let changed = try archiveObject(archive, changing: "iterations", to: 1)
        let data = try JSONSerialization.data(withJSONObject: changed)

        XCTAssertThrowsError(try service.importBackup(data: data, passphrase: passphrase)) {
            XCTAssertEqual($0 as? BackupService.BackupError, .invalidKDFParameters)
        }
    }

    func testTamperedCiphertextFailsAuthentication() throws {
        let service = BackupService()
        let archive = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)
        var object = try archiveObject(archive)
        var ciphertext = try XCTUnwrap(Data(base64Encoded: object["ciphertext"] as? String ?? ""))
        ciphertext[0] ^= 0x01
        object["ciphertext"] = ciphertext.base64EncodedString()
        let tampered = try JSONSerialization.data(withJSONObject: object)

        XCTAssertThrowsError(try service.importBackup(data: tampered, passphrase: passphrase)) {
            XCTAssertEqual($0 as? BackupService.BackupError, .authenticationFailed)
        }
    }

    func testExportRejectsWeakPassphrasesAndUnsupportedFinanceSchema() {
        let service = BackupService()
        XCTAssertThrowsError(try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: "short")) {
            XCTAssertEqual($0 as? BackupService.BackupError, .weakPassphrase)
        }
        XCTAssertThrowsError(try service.exportBackup(snapshot: FinanceSnapshot(schemaVersion: 99), passphrase: passphrase)) {
            XCTAssertEqual($0 as? BackupService.BackupError, .unsupportedFinanceSchema(99))
        }
    }

    func testSeparateExportsUseDifferentRandomSalts() throws {
        let service = BackupService()
        let first = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)
        let second = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)
        let firstObject = try archiveObject(first)
        let secondObject = try archiveObject(second)
        XCTAssertNotEqual(firstObject["salt"] as? String, secondObject["salt"] as? String)
    }

    func testWritesEncryptedArchiveAtomicallyToChosenURL() throws {
        let service = BackupService()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("my-finances.szb")
        let archive = try service.exportBackup(snapshot: FinanceSnapshot(), passphrase: passphrase)

        try service.writeBackup(archive, to: url)

        XCTAssertEqual(try Data(contentsOf: url), archive)
    }

    private func archiveObject(_ data: Data, changing key: String? = nil, to value: Int? = nil) throws -> [String: Any] {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        if let key, let value { object[key] = value }
        return object
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
