import XCTest
@testable import SavingsZakat

final class HawlCalculatorTests: XCTestCase {
    func testDueDateUsesEgyptianOfficialAnniversaryWhenNextYearBoundariesExist() throws {
        let records = [
            EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 4, gregorianStart: date("2026-10-01"), sourceURL: "https://example.org/1448-4", announcementDate: date("2026-09-30")),
            EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 5, gregorianStart: date("2026-10-31"), sourceURL: "https://example.org/1448-5", announcementDate: date("2026-10-30")),
            EgyptianHijriMonthStart(hijriYear: 1449, hijriMonth: 4, gregorianStart: date("2027-09-21"), sourceURL: "https://example.org/1449-4", announcementDate: date("2027-09-20")),
            EgyptianHijriMonthStart(hijriYear: 1449, hijriMonth: 5, gregorianStart: date("2027-10-20"), sourceURL: "https://example.org/1449-5", announcementDate: date("2027-10-19"))
        ]
        let egyptianCalendar = EgyptianHijriCalendar(officialMonthStarts: records, timeZone: TimeZone(secondsFromGMT: 0)!)
        let due = try XCTUnwrap(HawlCalculator.dueDateResult(startDate: date("2026-10-12"), egyptianCalendar: egyptianCalendar))

        XCTAssertEqual(due.date, date("2027-10-02"))
        XCTAssertEqual(due.status, .officiallyConfirmed)
    }

    func testHawlFallsBackToEstimatedWhenEgyptianNextYearIsNotPublished() throws {
        let due = try XCTUnwrap(HawlCalculator.dueDateResult(startDate: date("2026-07-15")))
        XCTAssertEqual(due.status, .estimated)
    }

    func testHawlIsNotCompleteBeforeDueDateAndCompleteOnDueDate() {
        let start = date("2026-07-15")
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
