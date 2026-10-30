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

    func testHawlAnniversaryUsesOfficialEgyptianMonthStartWhenBothBoundariesExist() throws {
        let records = [
            EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 4, gregorianStart: date("2026-10-01"), sourceURL: "https://example.org/official-1448-4", announcementDate: date("2026-09-30")),
            EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 5, gregorianStart: date("2026-10-31"), sourceURL: "https://example.org/official-1448-5", announcementDate: date("2026-10-30")),
            EgyptianHijriMonthStart(hijriYear: 1449, hijriMonth: 4, gregorianStart: date("2027-09-21"), sourceURL: "https://example.org/official-1449-4", announcementDate: date("2027-09-20")),
            EgyptianHijriMonthStart(hijriYear: 1449, hijriMonth: 5, gregorianStart: date("2027-10-20"), sourceURL: "https://example.org/official-1449-5", announcementDate: date("2027-10-19"))
        ]
        let calendar = EgyptianHijriCalendar(officialMonthStarts: records, timeZone: TimeZone(secondsFromGMT: 0)!)
        let due = try XCTUnwrap(calendar.anniversary(of: date("2026-10-12")))
        XCTAssertEqual(due.status, .officiallyConfirmed)
        XCTAssertEqual(due.date, date("2027-10-02"))
    }

    func testHawlAnniversaryFallsBackToEstimatedWhenNextYearIsNotCovered() throws {
        let records = [
            EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 4, gregorianStart: date("2026-10-01"), sourceURL: "https://example.org/official", announcementDate: date("2026-09-30")),
            EgyptianHijriMonthStart(hijriYear: 1448, hijriMonth: 5, gregorianStart: date("2026-10-31"), sourceURL: "https://example.org/official-next", announcementDate: date("2026-10-30"))
        ]
        let calendar = EgyptianHijriCalendar(officialMonthStarts: records, timeZone: TimeZone(secondsFromGMT: 0)!)
        let due = try XCTUnwrap(calendar.anniversary(of: date("2026-10-12")))
        XCTAssertEqual(due.status, .estimated)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
