import XCTest
@testable import SavingsZakat

final class FinancePreferencesTests: XCTestCase {
    func testEGPExchangeRateIsAlwaysNormalizedToOne() {
        let preferences = FinancePreferences(exchangeRatesToEGP: ["EGP": 0, "usd": 50])
        XCTAssertEqual(preferences.exchangeRatesToEGP["EGP"], 1)
        XCTAssertEqual(preferences.exchangeRatesToEGP["USD"], 50)
    }

    func testEnabledRulesExcludeDisabledShortOrEmptyRules() {
        let preferences = FinancePreferences(bankMessageRules: [
            BankMessageRule(keyword: "marketplace", direction: .expense, category: "Shopping"),
            BankMessageRule(keyword: "atm", direction: .expense, category: "Cash", isEnabled: false),
            BankMessageRule(keyword: "ab", direction: .income, category: "Short"),
            BankMessageRule(keyword: "salary", direction: .income, category: "   ")
        ])
        XCTAssertEqual(preferences.enabledBankMessageRules.map(\.keyword), ["marketplace"])
    }
    func testOlderPreferencesDecodeWithoutZakatSelectionOrSavedSnapshot() throws {
        let original = FinancePreferences()
        let encoded = try JSONEncoder().encode(original)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "selectedZakatMethod")
        object.removeValue(forKey: "savedZakatCalculation")
        let olderData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(FinancePreferences.self, from: olderData)

        XCTAssertEqual(decoded.effectiveZakatMethod, .separateHawlCombinedNisab)
        XCTAssertNil(decoded.savedZakatCalculation)
    }

    func testSelectedZakatMethodAndSavedCalculationRoundTrip() throws {
        let holding = Holding(
            id: UUID(), kind: .cash, amount: 10_000, currency: "EGP", grams: nil, carat: nil,
            acquiredDate: Date(timeIntervalSince1970: 1_700_000_000),
            hawlStartDate: Date(timeIntervalSince1970: 1_700_000_000),
            purpose: .investment
        )
        var preferences = FinancePreferences(
            exchangeRatesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: ["21": 4_000],
            nisabEGP: 5_000,
            selectedZakatMethod: .independentCategories
        )
        let result = ZakatCalculator.calculate(
            holdings: [holding], ratesToEGP: preferences.exchangeRatesToEGP,
            goldPricesPerGramEGP: preferences.goldPricesPerGramEGP,
            silverPricePerGramEGP: nil, nisabEGP: preferences.nisabEGP,
            asOf: Date(timeIntervalSince1970: 1_800_000_000),
            method: .independentCategories
        )
        preferences.savedZakatCalculation = SavedZakatCalculation(
            result: result, holdings: [holding], preferences: preferences
        )

        let decoded = try JSONDecoder().decode(FinancePreferences.self, from: JSONEncoder().encode(preferences))
        XCTAssertEqual(decoded.effectiveZakatMethod, .independentCategories)
        XCTAssertEqual(decoded.savedZakatCalculation?.zakatDueEGP, result.zakatDueEGP)
        XCTAssertEqual(decoded.savedZakatCalculation?.holdings, [holding])
        XCTAssertEqual(decoded.savedZakatCalculation?.goldPricesPerGramEGP["21"], 4_000)
    }

}
