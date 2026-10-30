import XCTest
@testable import SavingsZakat

final class AssetLedgerTests: XCTestCase {
    private let today = Date(timeIntervalSince1970: 1_760_000_000)
    private let acquired = Date(timeIntervalSince1970: 1_700_000_000)

    func testAddsCashGoldSilverAndManualInvestmentAssets() throws {
        let items = [
            cash(),
            gold(),
            silver(),
            investment()
        ]
        var ledger = AssetLedger()
        for item in items {
            try ledger.add(item, asOf: today)
        }
        XCTAssertEqual(ledger.holdings, items)
    }

    func testUpdatesAnExistingHoldingWithoutChangingItsIdentity() throws {
        let original = cash()
        var ledger = AssetLedger(holdings: [original])
        var changed = original
        changed.amount = 2_500
        changed.name = "Emergency cash"

        try ledger.update(changed, asOf: today)

        XCTAssertEqual(ledger.holdings, [changed])
        XCTAssertEqual(ledger.holdings.first?.id, original.id)
    }

    func testDeletesAnExistingHolding() throws {
        let item = gold()
        var ledger = AssetLedger(holdings: [item])

        try ledger.delete(id: item.id)

        XCTAssertTrue(ledger.holdings.isEmpty)
    }

    func testRejectsDuplicateIDsAndUnknownUpdatesOrDeletes() throws {
        let item = cash()
        var ledger = AssetLedger(holdings: [item])
        XCTAssertThrowsError(try ledger.add(item, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .duplicateHolding(item.id))
        }
        let missingID = UUID()
        var missing = item
        missing.id = missingID
        XCTAssertThrowsError(try ledger.update(missing, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .holdingNotFound(missingID))
        }
        XCTAssertThrowsError(try ledger.delete(id: missingID)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .holdingNotFound(missingID))
        }
    }

    func testRejectsZeroNegativeAndNonFiniteAmounts() throws {
        var ledger = AssetLedger()
        for value in [0.0, -1.0, Double.nan, Double.infinity] {
            var item = cash()
            item.amount = value
            XCTAssertThrowsError(try ledger.add(item, asOf: today))
        }
    }

    func testRejectsInvalidAcquisitionAndHawlDateOrder() throws {
        var ledger = AssetLedger()
        var futureAcquisition = cash()
        futureAcquisition.acquiredDate = today.addingTimeInterval(86_400)
        futureAcquisition.hawlStartDate = futureAcquisition.acquiredDate
        XCTAssertThrowsError(try ledger.add(futureAcquisition, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .invalidDates)
        }

        var hawlBeforeAcquisition = cash()
        hawlBeforeAcquisition.hawlStartDate = acquired.addingTimeInterval(-86_400)
        XCTAssertThrowsError(try ledger.add(hawlBeforeAcquisition, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .invalidDates)
        }
    }

    func testValidatesGoldCaratSilverPurityAndInvestmentName() throws {
        var ledger = AssetLedger()
        var invalidGold = gold()
        invalidGold.carat = 20
        XCTAssertThrowsError(try ledger.add(invalidGold, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .invalidGoldCarat)
        }

        var invalidSilver = silver()
        invalidSilver.purity = 700
        XCTAssertThrowsError(try ledger.add(invalidSilver, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .invalidSilverPurity)
        }

        var invalidInvestment = investment()
        invalidInvestment.name = "  "
        XCTAssertThrowsError(try ledger.add(invalidInvestment, asOf: today)) {
            XCTAssertEqual($0 as? AssetLedger.AssetError, .missingInvestmentName)
        }
    }

    func testSilverPurityChangesItsZakatValuation() {
        let item = silver()
        let result = ZakatCalculator.calculate(
            holdings: [item],
            ratesToEGP: ["EGP": 1],
            goldPricesPerGramEGP: [:],
            silverPricePerGramEGP: 100,
            nisabEGP: 1,
            asOf: today
        )
        XCTAssertEqual(result.totalValuedWealthEGP, 925, accuracy: 0.01)
    }

    func testManualInvestmentUsesItsCurrencyRateForZakatValuation() {
        let item = investment()
        let result = ZakatCalculator.calculate(
            holdings: [item],
            ratesToEGP: ["USD": 50],
            goldPricesPerGramEGP: [:],
            silverPricePerGramEGP: nil,
            nisabEGP: 1,
            asOf: today
        )
        XCTAssertEqual(result.totalValuedWealthEGP, 1_000, accuracy: 0.01)
    }

    private func cash() -> Holding {
        Holding(id: UUID(), kind: .cash, amount: 1_000, currency: "EGP", grams: nil, carat: nil,
                acquiredDate: acquired, hawlStartDate: acquired, purpose: .investment)
    }

    private func gold() -> Holding {
        Holding(id: UUID(), kind: .gold, amount: 10, currency: nil, grams: 10, carat: 21,
                acquiredDate: acquired, hawlStartDate: acquired, purpose: .investment)
    }

    private func silver() -> Holding {
        Holding(id: UUID(), kind: .silver, amount: 10, currency: nil, grams: 10, carat: nil,
                acquiredDate: acquired, hawlStartDate: acquired, purpose: .investment,
                name: "Silver lot", purity: 925)
    }

    private func investment() -> Holding {
        Holding(id: UUID(), kind: .investment, amount: 20, currency: "USD", grams: nil, carat: nil,
                acquiredDate: acquired, hawlStartDate: acquired, purpose: .investment,
                name: "Brokerage portfolio")
    }
}
