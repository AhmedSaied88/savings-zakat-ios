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

    func testPersonalUseGoldIsValuedButExcludedUnlessSettingIsEnabled() {
        let gold = Holding(
            id: UUID(), kind: .gold, amount: 10, currency: nil, grams: 10, carat: 21,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .personalUse
        )
        let excluded = ZakatCalculator.calculate(
            holdings: [gold], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: ["21": 5_000], silverPricePerGramEGP: nil,
            nisabEGP: 1_000, asOf: date("2026-10-29")
        )
        XCTAssertEqual(excluded.totalValuedWealthEGP, 50_000, accuracy: 0.01)
        XCTAssertEqual(excluded.excludedWealthEGP, 50_000, accuracy: 0.01)
        XCTAssertEqual(excluded.maturedEligibleWealthEGP, 0, accuracy: 0.01)
        XCTAssertEqual(excluded.zakatDueEGP, 0, accuracy: 0.01)
        XCTAssertEqual(excluded.breakdown.first?.status, .excludedPersonalUse)

        let included = ZakatCalculator.calculate(
            holdings: [gold], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: ["21": 5_000], silverPricePerGramEGP: nil,
            nisabEGP: 1_000, asOf: date("2026-10-29"), includePersonalGold: true
        )
        XCTAssertEqual(included.excludedWealthEGP, 0, accuracy: 0.01)
        XCTAssertEqual(included.maturedEligibleWealthEGP, 50_000, accuracy: 0.01)
        XCTAssertEqual(included.zakatDueEGP, 1_250, accuracy: 0.01)
        XCTAssertEqual(included.breakdown.first?.status, .included)
    }

    func testNisabBoundaryIsInclusiveAndCalculatesTwoPointFivePercent() {
        let cash = Holding(
            id: UUID(), kind: .cash, amount: 1_000, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .investment
        )
        let result = ZakatCalculator.calculate(
            holdings: [cash], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil,
            nisabEGP: 1_000, asOf: date("2026-10-29")
        )
        XCTAssertEqual(result.maturedEligibleWealthEGP, 1_000, accuracy: 0.01)
        XCTAssertEqual(result.zakatDueEGP, 25, accuracy: 0.01)
    }

    func testMissingMetalPricesAreVisibleInPerAssetBreakdown() {
        let gold = Holding(
            id: UUID(), kind: .gold, amount: 5, currency: nil, grams: 5, carat: 21,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .investment
        )
        let silver = Holding(
            id: UUID(), kind: .silver, amount: 20, currency: nil, grams: 20, carat: nil,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .investment, name: "Silver", purity: 925
        )
        let result = ZakatCalculator.calculate(
            holdings: [gold, silver], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil,
            nisabEGP: 1, asOf: date("2026-10-29")
        )
        XCTAssertTrue(result.isProvisional)
        XCTAssertEqual(result.breakdown.map(\.status), [.missingValuation, .missingValuation])
        XCTAssertEqual(result.totalValuedWealthEGP, 0, accuracy: 0.01)
        XCTAssertTrue(result.warnings.contains { $0.contains("gold resale price") })
        XCTAssertTrue(result.warnings.contains { $0.contains("silver price") })
    }

    func testInvalidHoldingAmountIsNotSilentlyTreatedAsZero() {
        let invalid = Holding(
            id: UUID(), kind: .cash, amount: -10, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .investment
        )
        let result = ZakatCalculator.calculate(
            holdings: [invalid], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil,
            nisabEGP: 1, asOf: date("2026-10-29")
        )
        XCTAssertTrue(result.isProvisional)
        XCTAssertEqual(result.breakdown.first?.status, .invalid)
        XCTAssertTrue(result.warnings.contains { $0.contains("Invalid amount") })
    }

    func testAsOfDateUsesCairoCivilDayBoundary() throws {
        let start = date("2026-07-15")
        let due = try XCTUnwrap(HawlCalculator.dueDate(startDate: start))
        let previousCairoDay = due.addingTimeInterval(-4 * 60 * 60)
        XCTAssertFalse(HawlCalculator.hasCompletedHawl(startDate: start, asOf: previousCairoDay))
        XCTAssertTrue(HawlCalculator.hasCompletedHawl(startDate: start, asOf: due))
    }


    func testUnmaturedAssetRemainsValuedButIsExcludedFromEligibleWealth() throws {
        let recent = Holding(
            id: UUID(), kind: .cash, amount: 200, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: date("2026-07-15"), hawlStartDate: date("2026-07-15"),
            purpose: .investment
        )
        let result = ZakatCalculator.calculate(
            holdings: [recent], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil,
            nisabEGP: 100, asOf: date("2026-10-29")
        )
        XCTAssertEqual(result.totalValuedWealthEGP, 200, accuracy: 0.01)
        XCTAssertEqual(result.maturedEligibleWealthEGP, 0, accuracy: 0.01)
        XCTAssertNotNil(result.nextDueDate)
        XCTAssertEqual(result.breakdown.first?.status, .waitingForHawl)
    }

    func testInvalidNisabProducesProvisionalZeroCalculation() {
        let cash = Holding(
            id: UUID(), kind: .cash, amount: 5_000, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .investment
        )
        let result = ZakatCalculator.calculate(
            holdings: [cash], ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: [:], silverPricePerGramEGP: nil,
            nisabEGP: 0, asOf: date("2026-10-29")
        )
        XCTAssertTrue(result.isProvisional)
        XCTAssertEqual(result.zakatDueEGP, 0, accuracy: 0.01)
        XCTAssertTrue(result.warnings.contains { $0.contains("valid nisab") })
    }

    func testUnsupportedGoldCaratIsNotValued() {
        let gold = Holding(
            id: UUID(), kind: .gold, amount: 5, currency: nil, grams: 5, carat: 20,
            acquiredDate: date("2024-01-01"), hawlStartDate: date("2024-01-01"),
            purpose: .investment
        )
        let result = ZakatCalculator.calculate(
            holdings: [gold], ratesToEGP: [:],
            goldPricesPerGramEGP: ["20": 5_000], silverPricePerGramEGP: nil,
            nisabEGP: 1, asOf: date("2026-10-29")
        )
        XCTAssertEqual(result.totalValuedWealthEGP, 0, accuracy: 0.01)
        XCTAssertTrue(result.warnings.contains { $0.contains("Unsupported gold carat") })
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
