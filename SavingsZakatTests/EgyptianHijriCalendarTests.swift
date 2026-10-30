import XCTest
@testable import SavingsZakat

final class EgyptianHijriCalendarTests: XCTestCase {
    func testDateInsideOfficialMonthIsMarkedConfirmed() throws {
        let start = date("2026-10-01")
        let record = EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 4, gregorianStart: start, sourceURL: "https://example.org/official", announcementDate: date("2026-09-30"))
        let next = EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 5, gregorianStart: date("2026-10-31"), sourceURL: "https://example.org/official-next", announcementDate: date("2026-10-30"))
        let calendar = EgyptianHijriCalendar(officialMonthStarts: [record, next], timeZone: TimeZone(secondsFromGMT: 0)!)
        let result = try XCTUnwrap(calendar.convert(date("2026-10-12")))
        XCTAssertEqual(result.status, .officiallyConfirmed)
        XCTAssertEqual(result.hijriYear, 1448)
        XCTAssertEqual(result.hijriMonth, 4)
        XCTAssertEqual(result.hijriDay, 12)
    }

    func testDateOutsideOfficialCoverageIsMarkedEstimated() throws {
        let record = EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 4, gregorianStart: date("2026-10-01"), sourceURL: "https://example.org/official", announcementDate: date("2026-09-30"))
        let calendar = EgyptianHijriCalendar(officialMonthStarts: [record], timeZone: TimeZone(secondsFromGMT: 0)!)
        let result = try XCTUnwrap(calendar.convert(date("2027-01-01")))
        XCTAssertEqual(result.status, .estimated)
    }

    func testGregorianDateBeforeFirstOfficialRecordIsEstimated() throws {
        let record = EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 4, gregorianStart: date("2026-10-01"), sourceURL: "https://example.org/official", announcementDate: date("2026-09-30"))
        let calendar = EgyptianHijriCalendar(officialMonthStarts: [record], timeZone: TimeZone(secondsFromGMT: 0)!)
        let result = try XCTUnwrap(calendar.convert(date("2026-09-20")))
        XCTAssertEqual(result.status, .estimated)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
