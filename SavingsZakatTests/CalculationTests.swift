import XCTest
@testable import SavingsZakat

final class HawlCalculatorTests: XCTestCase {
    func testDueDateIsOneIslamicCalendarYearAfterStart() throws {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = date("2025-01-01")
        let expected = try XCTUnwrap(calendar.date(byAdding: .year, value: 1, to: start))
        XCTAssertEqual(HawlCalculator.dueDate(startDate: start, calendar: calendar), calendar.startOfDay(for: expected))
    }

    func testHawlIsNotCompleteBeforeDueDateAndCompleteOnDueDate() {
        let start = date("2025-01-01")
        let due = try! XCTUnwrap(HawlCalculator.dueDate(startDate: start))
        XCTAssertFalse(HawlCalculator.hasCompletedHawl(startDate: start, asOf: due.addingTimeInterval(-86_400)))
        XCTAssertTrue(HawlCalculator.hasCompletedHawl(startDate: start, asOf: due))
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}

final class ZakatCalculatorTests: XCTestCase {
    func testCombinesAllMaturedAssetsThenCalculatesTwoPointFivePercent() {
        let asOf = date("2026-10-29")
        let cash = Holding(id: UUID(), kind: .cash, amount: 10_000, currency: "EGP", grams: nil, carat: nil, acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"), purpose: .investment)
        let sar = Holding(id: UUID(), kind: .cash, amount: 100, currency: "SAR", grams: nil, carat: nil, acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"), purpose: .investment)
        let result = ZakatCalculator.calculate(holdings: [cash, sar], ratesToEGP: ["EGP": 1, "SAR": 13], goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil, nisabEGP: 5_000, asOf: asOf)
        XCTAssertEqual(result.maturedEligibleWealthEGP, 11_300, accuracy: 0.01)
        XCTAssertEqual(result.zakatDueEGP, 282.5, accuracy: 0.01)
        XCTAssertTrue(result.isProvisional)
        XCTAssertTrue(result.warnings.contains { $0.contains("Hawl date") })
    }

    func testMissingCurrencyRateMakesResultProvisionalInsteadOfSilentlyCountingAsZero() {
        let holding = Holding(id: UUID(), kind: .cash, amount: 100, currency: "SAR", grams: nil, carat: nil, acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"), purpose: .investment)
        let result = ZakatCalculator.calculate(holdings: [holding], ratesToEGP: [:], goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil, nisabEGP: 1, asOf: date("2026-10-29"))
        XCTAssertTrue(result.isProvisional)
        XCTAssertFalse(result.warnings.isEmpty)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}