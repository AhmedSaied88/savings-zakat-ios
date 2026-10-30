import CryptoKit
import Foundation

enum BankParseConfidence: String, Codable, Equatable {
    case high
    case medium
}

struct ParsedBankMessage: Equatable {
    let title: String
    let amount: Decimal
    let currency: String
    let direction: TransactionDirection
    let category: String
    let confidence: BankParseConfidence
    let fingerprint: String
    let redactedSourceText: String
    let reviewStatus: TransactionReviewStatus = .needsReview
}

enum BankMessageParser {
    private static let amountRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(EGP|LE|USD|SAR|AED|EUR|GBP)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)\b|(?<!\d)([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(EGP|LE|USD|SAR|AED|EUR|GBP)\b"#
    )

    static func parse(_ message: String) -> ParsedBankMessage? {
        let normalized = SensitiveTextRedactor.normalizeDigits(in: message)
        guard let (amount, currency) = extractAmountAndCurrency(from: normalized),
              amount > 0,
              let classification = classify(normalized) else {
            return nil
        }

        let safeText = SensitiveTextRedactor.redact(message)
        let fingerprintInput = safeText
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let fingerprint = SHA256.hash(data: Data(fingerprintInput.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        return ParsedBankMessage(
            title: classification.category,
            amount: amount,
            currency: currency,
            direction: classification.direction,
            category: classification.category,
            confidence: classification.confidence,
            fingerprint: fingerprint,
            redactedSourceText: safeText
        )
    }

    static func redactedText(_ text: String) -> String {
        SensitiveTextRedactor.redact(text)
    }

    private static func extractAmountAndCurrency(from text: String) -> (Decimal, String)? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard amountRegex.numberOfMatches(in: text, range: range) == 1,
              let match = amountRegex.firstMatch(in: text, range: range) else { return nil }

        let currencyRange = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 4)
        let amountRange = match.range(at: 2).location != NSNotFound ? match.range(at: 2) : match.range(at: 3)
        guard let currencySwiftRange = Range(currencyRange, in: text),
              let amountSwiftRange = Range(amountRange, in: text) else { return nil }

        let rawCurrency = String(text[currencySwiftRange]).uppercased()
        let rawAmount = String(text[amountSwiftRange]).replacingOccurrences(of: ",", with: "")
        guard let amount = Decimal(string: rawAmount, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        return (amount, rawCurrency == "LE" ? "EGP" : rawCurrency)
    }

    private static func classify(_ text: String) -> (direction: TransactionDirection, category: String, confidence: BankParseConfidence)? {
        let lower = text.lowercased()

        let transfer = containsAny(["transfer", "transferred", "تحويل"], in: lower)
        let reversal = containsAny(["reversal", "reversed", "refund", "refunded", "عكس", "استرداد"], in: lower)
        let cardPayment = containsAny(["card payment", "credit card payment", "payment to card", "سداد البطاقة", "سداد بطاقة"], in: lower)
        let fee = containsAny(["fee", "commission", "charge", "رسوم", "عمولة"], in: lower)
        let atm = containsAny(["atm", "cash withdrawal", "withdrawal", "سحب نقدي", "سحب"], in: lower)
        let purchase = containsAny(["purchase", "pos", "spent", "شراء", "نقطة بيع"], in: lower)
        let income = containsAny(["received", "credited", "credit", "deposit", "salary", "تم إيداع", "تم استلام", "إضافة"], in: lower)
        let debit = containsAny(["debit", "deducted", "خصم"], in: lower)

        if transfer {
            return (.transfer, "Transfer", .medium)
        }
        if reversal {
            return (.income, "Reversal", .high)
        }
        if cardPayment {
            return (.expense, "Card payment", .high)
        }
        if fee {
            return (.expense, "Bank fee", .high)
        }
        if atm {
            return (.expense, "Cash withdrawal", .high)
        }
        if purchase {
            return (.expense, "Purchase", .high)
        }
        if income && debit {
            return nil
        }
        if income {
            return (.income, "Income", .high)
        }
        if debit {
            return (.expense, "Expense", .medium)
        }
        return nil
    }

    private static func containsAny(_ keywords: [String], in text: String) -> Bool {
        keywords.contains(where: { text.contains($0) })
    }


}
