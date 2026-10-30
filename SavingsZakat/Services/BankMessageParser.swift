import Foundation

struct ParsedBankMessage: Equatable {
    let title: String
    let amount: Decimal
    let currency: String
    let direction: TransactionDirection
    let redactedSourceText: String
    let reviewStatus: TransactionReviewStatus = .needsReview
}

enum BankMessageParser {
    private static let amountPattern = #"(?i)\b(EGP|LE|USD|SAR|AED|EUR|GBP)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)"#

    static func parse(_ message: String) -> ParsedBankMessage? {
        let safeText = redactedText(message)
        guard let range = message.range(of: amountPattern, options: .regularExpression) else { return nil }
        let match = String(message[range])
        let parts = match.replacingOccurrences(of: ",", with: "").split(whereSeparator: { $0.isWhitespace })
        guard parts.count == 2,
              let amount = Decimal(string: String(parts[1]), locale: Locale(identifier: "en_US_POSIX")),
              amount > 0 else { return nil }

        let rawCurrency = String(parts[0]).uppercased()
        let currency = rawCurrency == "LE" ? "EGP" : rawCurrency
        let lower = message.lowercased()
        let direction: TransactionDirection
        if ["received", "credited", "deposit", "تم إيداع", "تم استلام"].contains(where: { lower.contains($0) }) {
            direction = .income
        } else if ["purchase", "spent", "debit", "withdraw", "شراء", "خصم", "سحب"].contains(where: { lower.contains($0) }) {
            direction = .expense
        } else {
            return nil
        }

        return ParsedBankMessage(
            title: direction == .income ? "Bank credit" : "Bank transaction",
            amount: amount,
            currency: currency,
            direction: direction,
            redactedSourceText: safeText
        )
    }

    static func redactedText(_ text: String) -> String {
        var safe = text
        let patterns = [
            #"(?i)\b(?:otp|one[- ]time password|cvv|cvc|pin)\s*[:#-]?\s*\d{3,8}\b"#,
            #"(?<!\d)\d{12,19}(?!\d)"#
        ]
        for pattern in patterns {
            safe = safe.replacingOccurrences(of: pattern, with: "[REDACTED]", options: .regularExpression)
        }
        return safe
    }
}
