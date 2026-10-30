import XCTest
@testable import SavingsZakat

final class MessageImportCoordinatorTests: XCTestCase {
    func testRejectsEmptyMessageWithoutWritingQueue() throws {
        let url = temporaryQueueURL()
        let coordinator = MessageImportCoordinator(queueURL: url)

        XCTAssertThrowsError(try coordinator.importMessage(
            text: " \n ",
            senderIdentifier: "BANK",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        ))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testRedactsSecretsBeforePersistingImportedMessage() throws {
        let url = temporaryQueueURL()
        let coordinator = MessageImportCoordinator(queueURL: url)
        let raw = "Purchase EGP 90.00 OTP 123456 Card 1234567890123456"

        let outcome = try coordinator.importMessage(
            text: raw,
            senderIdentifier: "BANK",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        )

        guard case .imported(let message) = outcome else {
            return XCTFail("Expected a new import")
        }
        XCTAssertFalse(message.redactedText.contains("123456"))
        let stored = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(stored.contains("123456"))
        XCTAssertTrue(stored.contains("[REDACTED]"))
    }

    func testRepeatedDeliveryFromSameSenderWithinWindowIsDuplicate() throws {
        let url = temporaryQueueURL()
        let coordinator = MessageImportCoordinator(queueURL: url, duplicateWindow: 300)
        let receivedAt = Date(timeIntervalSince1970: 1_760_000_000)

        let first = try coordinator.importMessage(
            text: "Purchase EGP 90.00 OTP 123456",
            senderIdentifier: "BANK",
            receivedAt: receivedAt
        )
        let second = try coordinator.importMessage(
            text: "Purchase EGP 90.00 OTP 654321",
            senderIdentifier: "bank",
            receivedAt: receivedAt.addingTimeInterval(120)
        )

        guard case .imported = first else { return XCTFail("First delivery should import") }
        guard case .duplicate = second else { return XCTFail("Second delivery should be a duplicate") }
        XCTAssertEqual(try coordinator.loadMessages().count, 1)
    }

    func testSameMessageFromDifferentSenderIsNotDuplicate() throws {
        let coordinator = MessageImportCoordinator(queueURL: temporaryQueueURL())
        let receivedAt = Date(timeIntervalSince1970: 1_760_000_000)

        _ = try coordinator.importMessage(text: "Purchase EGP 90.00", senderIdentifier: "BANK-A", receivedAt: receivedAt)
        let second = try coordinator.importMessage(text: "Purchase EGP 90.00", senderIdentifier: "BANK-B", receivedAt: receivedAt)

        guard case .imported = second else { return XCTFail("Different sender should not be deduplicated") }
        XCTAssertEqual(try coordinator.loadMessages().count, 2)
    }

    func testSameMessageAfterDuplicateWindowCanBeImportedAgain() throws {
        let coordinator = MessageImportCoordinator(queueURL: temporaryQueueURL(), duplicateWindow: 300)
        let receivedAt = Date(timeIntervalSince1970: 1_760_000_000)

        _ = try coordinator.importMessage(text: "Purchase EGP 90.00", senderIdentifier: "BANK", receivedAt: receivedAt)
        let second = try coordinator.importMessage(
            text: "Purchase EGP 90.00",
            senderIdentifier: "BANK",
            receivedAt: receivedAt.addingTimeInterval(301)
        )

        guard case .imported = second else { return XCTFail("Delivery outside the window should import") }
        XCTAssertEqual(try coordinator.loadMessages().count, 2)
    }

    func testUnparsedMessageIsRetainedForManualReview() throws {
        let coordinator = MessageImportCoordinator(queueURL: temporaryQueueURL())

        let outcome = try coordinator.importMessage(
            text: "Your account has an update. OTP 123456",
            senderIdentifier: "BANK",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        )

        guard case .imported(let message) = outcome else {
            return XCTFail("Unparsed messages must be retained")
        }
        XCTAssertEqual(message.state, .needsReview)
        XCTAssertNil(message.amount)
        XCTAssertNil(message.direction)
        XCTAssertTrue(message.redactedText.contains("[REDACTED]"))
    }

    func testQueueSurvivesCoordinatorRecreation() throws {
        let url = temporaryQueueURL()
        let first = MessageImportCoordinator(queueURL: url)
        _ = try first.importMessage(
            text: "Salary credited EGP 5,000.00",
            senderIdentifier: "BANK",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        )

        let second = MessageImportCoordinator(queueURL: url)
        XCTAssertEqual(try second.loadMessages().count, 1)
        XCTAssertEqual(try second.loadMessages().first?.state, .needsReview)
    }


    func testRejectsMissingSenderIdentifier() throws {
        let url = temporaryQueueURL()
        let coordinator = MessageImportCoordinator(queueURL: url)

        XCTAssertThrowsError(try coordinator.importMessage(
            text: "Purchase EGP 10.00",
            senderIdentifier: "   ",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        ))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testRejectsOversizedPayload() throws {
        let url = temporaryQueueURL()
        let coordinator = MessageImportCoordinator(queueURL: url)

        XCTAssertThrowsError(try coordinator.importMessage(
            text: String(repeating: "A", count: 10_001),
            senderIdentifier: "BANK",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        ))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }


    func testUntrustedSenderTextIsNotPersistedAsSenderMetadata() throws {
        let coordinator = MessageImportCoordinator(queueURL: temporaryQueueURL())

        let outcome = try coordinator.importMessage(
            text: "Purchase EGP 10.00",
            senderIdentifier: "BANK OTP: 123456",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000)
        )

        guard case .imported(let message) = outcome else {
            return XCTFail("Expected message to be imported")
        }
        XCTAssertEqual(message.senderIdentifier, "Unknown")
        XCTAssertFalse(message.senderIdentifier.contains("123456"))
    }


    func testConcurrentRepeatedDeliveriesCreateOnlyOneQueueEntry() throws {
        let url = temporaryQueueURL()
        let receivedAt = Date(timeIntervalSince1970: 1_760_000_000)
        let resultsLock = NSLock()
        var outcomes: [MessageImportCoordinator.ImportOutcome] = []

        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            let coordinator = MessageImportCoordinator(queueURL: url)
            let outcome = try? coordinator.importMessage(
                text: "Purchase EGP 90.00",
                senderIdentifier: "BANK",
                receivedAt: receivedAt
            )
            if let outcome {
                resultsLock.lock()
                outcomes.append(outcome)
                resultsLock.unlock()
            }
        }

        XCTAssertEqual(outcomes.count, 10)
        XCTAssertEqual(outcomes.filter {
            if case .imported = $0 { return true }
            return false
        }.count, 1)
        XCTAssertEqual(try MessageImportCoordinator(queueURL: url).loadMessages().count, 1)
    }

    private func temporaryQueueURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("MessageImportTests-\(UUID().uuidString).json")
    }
}
