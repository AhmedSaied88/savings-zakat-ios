import Foundation

enum ImportedMessageState: String, Codable {
    case needsReview
    case confirmed
    case ignored
}

struct ImportedMessage: Identifiable, Codable, Equatable {
    var id: UUID
    var senderIdentifier: String
    var receivedAt: Date
    var fingerprint: String
    var redactedText: String
    var amount: Decimal
    var currency: String
    var direction: TransactionDirection
    var category: String
    var confidence: BankParseConfidence
    var state: ImportedMessageState
    var linkedTransactionID: UUID?

    init(
        id: UUID = UUID(),
        senderIdentifier: String,
        receivedAt: Date,
        parsed: ParsedBankMessage,
        state: ImportedMessageState = .needsReview,
        linkedTransactionID: UUID? = nil
    ) {
        self.id = id
        self.senderIdentifier = senderIdentifier
        self.receivedAt = receivedAt
        self.fingerprint = parsed.fingerprint
        self.redactedText = parsed.redactedSourceText
        self.amount = parsed.amount
        self.currency = parsed.currency
        self.direction = parsed.direction
        self.category = parsed.category
        self.confidence = parsed.confidence
        self.state = state
        self.linkedTransactionID = linkedTransactionID
    }
}
