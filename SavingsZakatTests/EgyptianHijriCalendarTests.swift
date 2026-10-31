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
        XCTAssertTrue(result.calculationNote?.contains("not an official") == true)
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


    func testBundledEgyptianMuharramStartIsConfirmedWithSource() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        let result = try XCTUnwrap(calendar.convert(date("2026-06-16")))
        XCTAssertEqual(result.hijriYear, 1448)
        XCTAssertEqual(result.hijriMonth, 1)
        XCTAssertEqual(result.hijriDay, 1)
        XCTAssertEqual(result.status, .officiallyConfirmed)
        XCTAssertTrue(result.sourceURL?.contains("dar-alifta.org") == true)
    }

    func testBundledMonthBoundaryTransitionsFromMuharramToSafar() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        let lastMuharramDay = try XCTUnwrap(calendar.convert(date("2026-07-14")))
        let firstSafarDay = try XCTUnwrap(calendar.convert(date("2026-07-15")))

        XCTAssertEqual(lastMuharramDay.hijriMonth, 1)
        XCTAssertEqual(lastMuharramDay.hijriDay, 29)
        XCTAssertEqual(lastMuharramDay.status, .officiallyConfirmed)
        XCTAssertEqual(firstSafarDay.hijriMonth, 2)
        XCTAssertEqual(firstSafarDay.hijriDay, 1)
        XCTAssertEqual(firstSafarDay.status, .officiallyConfirmed)
    }

    func testLastBundledAnnouncementConfirmsOnlyItsFirstDayUntilNextMonthIsPublished() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        let firstDay = try XCTUnwrap(calendar.convert(date("2026-10-12")))
        let followingDay = try XCTUnwrap(calendar.convert(date("2026-10-13")))

        XCTAssertEqual(firstDay.hijriMonth, 5)
        XCTAssertEqual(firstDay.hijriDay, 1)
        XCTAssertEqual(firstDay.status, .officiallyConfirmed)
        XCTAssertEqual(followingDay.status, .estimated)
    }

    func testBundledCalendarContainsOrderedConsecutiveMonthRecordsWithProvenance() {
        let records = EgyptianCalendarRepository.officialMonthStarts
        XCTAssertEqual(records.count, 16)
        XCTAssertEqual(
            records.map { "\($0.hijriYear)-\($0.hijriMonth)" },
            ["1447-1", "1447-2", "1447-3", "1447-4", "1447-5", "1447-6",
             "1447-7", "1447-8", "1447-9", "1447-11", "1447-12",
             "1448-1", "1448-2", "1448-3", "1448-4", "1448-5"]
        )
        XCTAssertTrue(records.allSatisfy { $0.sourceURL.contains("dar-alifta.org") })
        XCTAssertTrue(records.allSatisfy { $0.announcementDate <= $0.gregorianStart })
    }


    func testGapInOfficialMonthRecordsDoesNotConfirmUnboundedDays() throws {
        let records = [
            EgyptianHijriMonthStart(
                hijriYear: 1448, hijriMonth: 1, gregorianStart: date("2026-06-16"),
                sourceURL: "https://example.org/muharram", announcementDate: date("2026-06-15")
            ),
            EgyptianHijriMonthStart(
                hijriYear: 1448, hijriMonth: 3, gregorianStart: date("2026-08-14"),
                sourceURL: "https://example.org/rabi", announcementDate: date("2026-08-13")
            )
        ]
        let calendar = EgyptianHijriCalendar(officialMonthStarts: records, timeZone: TimeZone(secondsFromGMT: 0)!)

        XCTAssertEqual(try XCTUnwrap(calendar.convert(date("2026-06-16"))).status, .officiallyConfirmed)
        XCTAssertEqual(try XCTUnwrap(calendar.convert(date("2026-06-17"))).status, .estimated)
    }

    func testBundledRamadanToDhuAlQidahGapDoesNotCreateFalseConfirmedInterval() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        let dayAfterRamadanStart = try XCTUnwrap(calendar.convert(date("2026-02-20")))
        let firstDhuAlQidahDay = try XCTUnwrap(calendar.convert(date("2026-04-19")))

        XCTAssertEqual(dayAfterRamadanStart.status, .estimated)
        XCTAssertEqual(firstDhuAlQidahDay.hijriYear, 1447)
        XCTAssertEqual(firstDhuAlQidahDay.hijriMonth, 11)
        XCTAssertEqual(firstDhuAlQidahDay.hijriDay, 1)
        XCTAssertEqual(firstDhuAlQidahDay.status, .officiallyConfirmed)
    }

    func testBundledDhuAlHijjahToMuharramBoundaryIsConfirmed() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        let lastDhuAlHijjahDay = try XCTUnwrap(calendar.convert(date("2026-06-15")))
        let firstMuharramDay = try XCTUnwrap(calendar.convert(date("2026-06-16")))

        XCTAssertEqual(lastDhuAlHijjahDay.hijriYear, 1447)
        XCTAssertEqual(lastDhuAlHijjahDay.hijriMonth, 12)
        XCTAssertEqual(lastDhuAlHijjahDay.status, .officiallyConfirmed)
        XCTAssertEqual(firstMuharramDay.hijriYear, 1448)
        XCTAssertEqual(firstMuharramDay.hijriMonth, 1)
        XCTAssertEqual(firstMuharramDay.hijriDay, 1)
        XCTAssertEqual(firstMuharramDay.status, .officiallyConfirmed)
    }


    func testUncoveredDateUsesEgyptianAstronomicalEstimateAndRemainsEstimated() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(identifier: "Africa/Cairo")!)
        let result = try XCTUnwrap(calendar.convert(date("2026-11-15")))

        XCTAssertEqual(result.status, .estimated)
        XCTAssertGreaterThanOrEqual(result.hijriDay, 1)
        XCTAssertLessThanOrEqual(result.hijriDay, 30)
        XCTAssertTrue(result.calculationNote?.contains("Egyptian astronomical estimate") == true)
        XCTAssertTrue(result.calculationNote?.contains("Cairo") == true)
    }


    func testEgyptianVisibilityCriteriaAcceptsInclusiveMinimums() {
        let conjunction = date("2026-10-10")
        let sunset = conjunction.addingTimeInterval(16 * 60 * 60)
        let moonset = sunset.addingTimeInterval(10 * 60)

        XCTAssertTrue(EgyptianAstronomicalEstimator.meetsEgyptianVisibilityCriteria(
            conjunction: conjunction,
            sunset: sunset,
            moonset: moonset,
            elongationDegrees: 8
        ))
    }

    func testEgyptianVisibilityCriteriaRejectsElongationBelowEightDegrees() {
        let conjunction = date("2026-10-10")
        let sunset = conjunction.addingTimeInterval(16 * 60 * 60)

        XCTAssertFalse(EgyptianAstronomicalEstimator.meetsEgyptianVisibilityCriteria(
            conjunction: conjunction,
            sunset: sunset,
            moonset: sunset.addingTimeInterval(20 * 60),
            elongationDegrees: 7.99
        ))
    }

    func testEgyptianVisibilityCriteriaRejectsMoonsetLagBelowTenMinutes() {
        let conjunction = date("2026-10-10")
        let sunset = conjunction.addingTimeInterval(16 * 60 * 60)

        XCTAssertFalse(EgyptianAstronomicalEstimator.meetsEgyptianVisibilityCriteria(
            conjunction: conjunction,
            sunset: sunset,
            moonset: sunset.addingTimeInterval(9 * 60 + 59),
            elongationDegrees: 12
        ))
    }

    func testEgyptianVisibilityCriteriaRejectsConjunctionAfterSunset() {
        let sunset = date("2026-10-10").addingTimeInterval(16 * 60 * 60)

        XCTAssertFalse(EgyptianAstronomicalEstimator.meetsEgyptianVisibilityCriteria(
            conjunction: sunset.addingTimeInterval(1),
            sunset: sunset,
            moonset: sunset.addingTimeInterval(20 * 60),
            elongationDegrees: 12
        ))
    }


    func testDaysAfterLatestOfficialStartRemainEstimatedAndUseItsMonthLabel() throws {
        let calendar = EgyptianCalendarRepository.makeCalendar(timeZone: TimeZone(identifier: "Africa/Cairo")!)
        let result = try XCTUnwrap(calendar.convert(date("2026-10-13")))

        XCTAssertEqual(result.hijriYear, 1448)
        XCTAssertEqual(result.hijriMonth, 5)
        XCTAssertEqual(result.hijriDay, 2)
        XCTAssertEqual(result.status, .estimated)
        XCTAssertTrue(result.calculationNote?.contains("latest official month start") == true)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
