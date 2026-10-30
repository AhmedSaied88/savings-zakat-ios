import XCTest
@testable import SavingsZakat

final class BankMessageParserTests: XCTestCase {
    func testParsesEnglishDebitMessageAsNeedsReview() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("Purchase of EGP 125.50 at MARKET on 30/10/2026"))
        XCTAssertEqual(result.direction, .expense)
        XCTAssertEqual(result.amount, Decimal(string: "125.50"))
        XCTAssertEqual(result.currency, "EGP")
        XCTAssertEqual(result.reviewStatus, .needsReview)
    }

    func testParsesCreditMessageAsIncome() throws {
        let result = try XCTUnwrap(BankMessageParser.parse("You received EGP 2,500.00 from transfer"))
        XCTAssertEqual(result.direction, .income)
        XCTAssertEqual(result.amount, Decimal(string: "2500.00"))
    }

    func testRedactsCardAndOtpLikeNumbersFromRetainedText() {
        let text = "Card 1234567890123456 purchase EGP 90.00 OTP 123456"
        let safe = BankMessageParser.redactedText(text)
        XCTAssertFalse(safe.contains("1234567890123456"))
        XCTAssertFalse(safe.contains("123456"))
    }

    func testUnknownMessageIsNotGuessed() {
        XCTAssertNil(BankMessageParser.parse("Your account has an update."))
    }
}
