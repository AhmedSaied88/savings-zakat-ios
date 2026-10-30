import Foundation

struct MonthlyFinanceSummary: Identifiable, Equatable {
    let month: Date
    let currency: String
    let income: Decimal
    let expenses: Decimal

    var net: Decimal { income - expenses }
    var id: String { "\(month.timeIntervalSince1970)-\(currency)" }
}

enum FinanceInsights {
    static func monthlySummaries(
        transactions: [FinanceTransaction],
        monthCount: Int = 6,
        asOf: Date = Date(),
        timeZone: TimeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
    ) -> [MonthlyFinanceSummary] {
        guard monthCount > 0 else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let currentComponents = calendar.dateComponents([.year, .month], from: asOf)
        guard let currentMonth = calendar.date(from: currentComponents) else { return [] }

        let months = (0..<monthCount).compactMap {
            calendar.date(byAdding: .month, value: -$0, to: currentMonth)
        }.sorted()

        let firstMonth = months.first ?? currentMonth
        let lastMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth

        struct Key: Hashable {
            let month: Date
            let currency: String
        }
        struct Totals {
            var income: Decimal = 0
            var expenses: Decimal = 0
        }

        var totals: [Key: Totals] = [:]
        var currencies = Set<String>()

        for transaction in transactions where transaction.reviewStatus == .confirmed {
            guard transaction.direction == .income || transaction.direction == .expense else { continue }
            let monthComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            guard let month = calendar.date(from: monthComponents),
                  month >= firstMonth, month < lastMonth else { continue }

            let currency = transaction.currency.uppercased()
            currencies.insert(currency)
            let key = Key(month: month, currency: currency)
            if transaction.direction == .income {
                totals[key, default: Totals()].income += transaction.amount
            } else {
                totals[key, default: Totals()].expenses += transaction.amount
            }
        }

        return currencies.sorted().flatMap { currency in
            months.map { month in
                let value = totals[Key(month: month, currency: currency)] ?? Totals()
                return MonthlyFinanceSummary(
                    month: month,
                    currency: currency,
                    income: value.income,
                    expenses: value.expenses
                )
            }
        }
    }
}
