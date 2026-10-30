import XCTest
@testable import SavingsZakat

final class BankMessageParserTests: XCTestCase {
    func testParsesEnglishDebitMessageAsNeedsReview() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Purchase of EGP 125.50 at MARKET on 30/10/2026"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.amount, Decimal(string: "125.50"))
        XCTAssertEqual(result.currency, "EGP")
        XCTAssertEqual(result.category, "Purchase")
        XCTAssertEqual(result.confidence, .high)
        XCTAssertEqual(result.reviewStatus, .needsReview)
    }

    func testParsesCreditMessageAsIncome() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Your salary was credited EGP 2,500.00"))
        XCTAssertEqual(result.direction, .transfer)
        XCTAssertEqual(result.amount, Decimal(string: "2500.00"))
        XCTAssertEqual(result.category, "Transfer")
    }

    func testParsesOutgoingTransferAsTransfer() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Transfer sent EGP 500.00 to another account"))
        XCTAssertEqual(result.direction, .transfer)
        XCTAssertEqual(result.category, "Transfer")
    }

    func testParsesAmountBeforeCurrency() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("You spent 45.75 EGP at a store"))
        XCTAssertEqual(result.amount, Decimal(string: "45.75"))
        XCTAssertEqual(result.currency, "EGP")
        XCTAssertEqual(result.direction, .expense)
    }

    func testParsesATMCashWithdrawal() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("ATM cash withdrawal EGP 1,000.00"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.category, "Cash withdrawal")
        XCTAssertEqual(result.amount, Decimal(string: "1000.00"))
    }

    func testParsesPOSPurchase() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("POS purchase EGP 220.00"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.category, "Purchase")
    }

    func testParsesBankFee() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Monthly service fee EGP 25.00"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.category, "Bank fee")
    }

    func testParsesReversalAsIncomeForReview() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Purchase reversal EGP 125.00"))
        XCTAssertEqual(result.direction, .income)
        XCTAssertEqual(result.category, "Reversal")
        XCTAssertEqual(result.reviewStatus, .needsReview)
    }

    func testParsesCreditCardPayment() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Credit card payment EGP 800.00"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.category, "Card payment")
    }

    func testArabicTransactionKeywordsAndArabicIndicDigits() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("تم سحب EGP ١٢٥.٥٠ من ماكينة ATM"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.amount, Decimal(string: "125.50"))
        XCTAssertEqual(result.category, "Cash withdrawal")
    }

    func testRedactsCardAndOtpLikeNumbersFromRetainedText() {
        let text = "Card 1234567890123456 purchase EGP 90.00 OTP 123456"
        let safe = BankMessageParser.redactedText(text)
        XCTAssertFalse(safe.contains("1234567890123456"))
        XCTAssertFalse(safe.contains("123456"))
    }

    func testRedactsArabicVerificationCode() {
        let safe = BankMessageParser.redactedText("رمز التحقق: 123456 لإتمام العملية")
        XCTAssertFalse(safe.contains("123456"))
        XCTAssertTrue(safe.contains("[REDACTED]"))
    }

    func testIdenticalMessagesHaveStableFingerprintAfterSecretRedaction() throws {
        let first = try XCTUnwrap(BankMessageParser.parse("Purchase EGP 90.00 OTP 123456"))
        let second = try XCTUnwrap(BankMessageParser.parse("Purchase EGP 90.00 OTP 654321"))
        XCTAssertEqual(first.fingerprint, second.fingerprint)
        XCTAssertEqual(first.redactedSourceText, second.redactedSourceText)
    }

    func testImportedMessagePersistsOnlyRedactedSourceAndNeedsReviewState() throws {
        let parsed = try XCTUnwrap(BankMessageParser.parse("Purchase EGP 90.00 OTP 123456"))
        let imported = ImportedMessage(
            senderIdentifier: "BANK",
            receivedAt: Date(timeIntervalSince1970: 1_760_000_000),
            parsed: parsed
        )
        let data = try JSONEncoder().encode(imported)
        let json = String(decoding: data, as: UTF8.self)
        let decoded = try JSONDecoder().decode(ImportedMessage.self, from: data)

        XCTAssertEqual(imported.state, .needsReview)
        XCTAssertFalse(json.contains("123456"))
        XCTAssertTrue(json.contains("[REDACTED]"))
        XCTAssertEqual(decoded, imported)
    }

    func testRedactsAlphanumericBankingPassword() {
        let safe = SensitiveTextRedactor.redact("Banking password: A1B2C3D4")
        XCTAssertFalse(safe.contains("A1B2C3D4"))
        XCTAssertTrue(safe.contains("[REDACTED]"))
    }

    func testAmbiguousMessageIsNotGuessed() {
        XCTAssertNil(BankMessageParser.parse("You received and debited EGP 100.00"))
        XCTAssertNil(BankMessageParser.parse("Your account has an update."))
        XCTAssertNil(BankMessageParser.parse("Purchase EGP 100.00. Available balance EGP 900.00."))
    }
}
