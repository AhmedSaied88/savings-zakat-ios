import CryptoKit
import Foundation

struct MessageImportCoordinator {
    enum ImportError: Error, Equatable {
        case emptyMessage
        case messageTooLong
        case invalidSender
    }

    enum ImportOutcome: Equatable {
        case imported(ImportedMessage)
        case duplicate(ImportedMessage)
    }

    private let queueURL: URL
    private let duplicateWindow: TimeInterval
    private let fileManager: FileManager

    init(
        queueURL: URL? = nil,
        duplicateWindow: TimeInterval = 300,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.duplicateWindow = max(0, duplicateWindow)
        if let queueURL {
            self.queueURL = queueURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let directory = support.appendingPathComponent("SavingsZakat", isDirectory: true)
            self.queueURL = directory.appendingPathComponent("imported-messages.json")
        }
    }

    @discardableResult
    func importMessage(
        text: String,
        senderIdentifier: String,
        receivedAt: Date = Date()
    ) throws -> ImportOutcome {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyMessage
        }
        guard text.count <= 10_000 else {
            throw ImportError.messageTooLong
        }

        let sender = senderIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sender.isEmpty else { throw ImportError.invalidSender }
        let safeSender = String(sender.prefix(64))
        let redactedText = SensitiveTextRedactor.redact(text)
        let parsed = BankMessageParser.parse(text)
        let fingerprint = parsed?.fingerprint ?? Self.fingerprint(for: redactedText)

        var messages = try loadMessages()
        if let duplicate = messages.first(where: {
            $0.senderIdentifier.caseInsensitiveCompare(safeSender) == .orderedSame &&
            $0.fingerprint == fingerprint &&
            abs(receivedAt.timeIntervalSince($0.receivedAt)) <= duplicateWindow
        }) {
            return .duplicate(duplicate)
        }

        let imported = ImportedMessage(
            senderIdentifier: safeSender,
            receivedAt: receivedAt,
            parsed: parsed,
            redactedText: redactedText,
            fingerprint: fingerprint
        )
        messages.append(imported)
        try saveMessages(messages)
        return .imported(imported)
    }

    func loadMessages() throws -> [ImportedMessage] {
        guard fileManager.fileExists(atPath: queueURL.path) else { return [] }
        let data = try Data(contentsOf: queueURL)
        return try JSONDecoder().decode([ImportedMessage].self, from: data)
    }

    func saveMessages(_ messages: [ImportedMessage]) throws {
        try fileManager.createDirectory(
            at: queueURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(messages)
        try data.write(to: queueURL, options: .atomic)
        NotificationCenter.default.post(name: .bankMessageImportDidChange, object: nil)
    }

    private static func fingerprint(for redactedText: String) -> String {
        let normalized = redactedText
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return SHA256.hash(data: Data(normalized.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

extension Notification.Name {
    static let bankMessageImportDidChange = Notification.Name("SavingsZakat.BankMessageImportDidChange")
}
