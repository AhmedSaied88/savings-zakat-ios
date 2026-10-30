import XCTest
@testable import SavingsZakat

final class FinanceInsightsTests: XCTestCase {
    func testMonthlySummaryUsesOnlyConfirmedIncomeAndExpenses() {
        let accountID = UUID()
        let transactions = [
            transaction("Salary", 5_000, .income, "EGP", accountID, status: .confirmed, date: date("2026-10-02")),
            transaction("Groceries", 1_000, .expense, "EGP", accountID, status: .confirmed, date: date("2026-10-03")),
            transaction("Pending import", 800, .expense, "EGP", accountID, status: .needsReview, date: date("2026-10-04")),
            transaction("Own transfer", 500, .transfer, "EGP", accountID, status: .confirmed, date: date("2026-10-05"))
        ]

        let summaries = FinanceInsights.monthlySummaries(
            transactions: transactions,
            monthCount: 1,
            asOf: date("2026-10-20"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].income, 5_000)
        XCTAssertEqual(summaries[0].expenses, 1_000)
        XCTAssertEqual(summaries[0].net, 4_000)
    }

    func testMonthlySummariesKeepDifferentCurrenciesSeparate() {
        let accountID = UUID()
        let transactions = [
            transaction("Salary", 1_000, .income, "EGP", accountID, status: .confirmed, date: date("2026-10-02")),
            transaction("Freelance", 100, .income, "USD", accountID, status: .confirmed, date: date("2026-10-03"))
        ]
        let summaries = FinanceInsights.monthlySummaries(
            transactions: transactions,
            monthCount: 1,
            asOf: date("2026-10-20"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(summaries.map(\.currency), ["EGP", "USD"])
        XCTAssertEqual(summaries.map(\.income), [1_000, 100])
    }

    func testReturnsChronologicalMonthsAndZeroFillsMonthsWithoutActivity() {
        let accountID = UUID()
        let transactions = [
            transaction("Salary", 1_000, .income, "EGP", accountID, status: .confirmed, date: date("2026-08-02")),
            transaction("Salary", 2_000, .income, "EGP", accountID, status: .confirmed, date: date("2026-10-02"))
        ]
        let summaries = FinanceInsights.monthlySummaries(
            transactions: transactions,
            monthCount: 3,
            asOf: date("2026-10-20"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(summaries.map { monthKey($0.month) }, ["2026-08", "2026-09", "2026-10"])
        XCTAssertEqual(summaries.map(\.income), [1_000, 0, 2_000])
    }

    func testReturnsNoSummariesWhenThereAreNoConfirmedTransactions() {
        let pending = transaction("Pending", 100, .expense, "EGP", UUID(), status: .needsReview, date: date("2026-10-01"))
        XCTAssertTrue(FinanceInsights.monthlySummaries(
            transactions: [pending], monthCount: 6, asOf: date("2026-10-20")
        ).isEmpty)
    }

    private func transaction(
        _ title: String,
        _ amount: Decimal,
        _ direction: TransactionDirection,
        _ currency: String,
        _ accountID: UUID,
        status: TransactionReviewStatus,
        date: Date
    ) -> FinanceTransaction {
        FinanceTransaction(
            title: title, amount: amount, currency: currency, direction: direction,
            date: date, accountID: accountID, reviewStatus: status
        )
    }

    private func monthKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: value)!
    }
}
