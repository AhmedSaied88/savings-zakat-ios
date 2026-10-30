import XCTest
@testable import SavingsZakat

final class FinancePreferencesTests: XCTestCase {
    func testEGPExchangeRateIsAlwaysNormalizedToOne() {
        let preferences = FinancePreferences(exchangeRatesToEGP: ["EGP": 0, "USD": 50])
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
}
