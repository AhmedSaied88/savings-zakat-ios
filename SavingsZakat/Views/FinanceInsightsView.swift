import SwiftUI
import Charts

struct FinanceInsightsView: View {
    let snapshot: FinanceSnapshot

    private var summaries: [MonthlyFinanceSummary] {
        FinanceInsights.monthlySummaries(
            transactions: snapshot.transactions,
            monthCount: 6,
            asOf: Date()
        )
    }

    private var currencyGroups: [(currency: String, values: [MonthlyFinanceSummary])] {
        let grouped = Dictionary(grouping: summaries, by: \.currency)
        return grouped.keys.sorted().map { currency in
            (currency, grouped[currency] ?? [])
        }
    }

    var body: some View {
        List {
            if summaries.isEmpty {
                ContentUnavailableView(
                    "No monthly activity yet",
                    systemImage: "chart.bar",
                    description: Text("Confirmed income and expenses will appear here. Pending imports and own-account transfers are excluded.")
                )
            }

            ForEach(currencyGroups, id: \.currency) { group in
                Section("\(group.currency) · last 6 months") {
                    Chart(group.values) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Income", NSDecimalNumber(decimal: item.income).doubleValue)
                        )
                        .foregroundStyle(by: .value("Type", "Income"))
                        .position(by: .value("Type", "Income"))

                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Expenses", NSDecimalNumber(decimal: item.expenses).doubleValue)
                        )
                        .foregroundStyle(by: .value("Type", "Expenses"))
                        .position(by: .value("Type", "Expenses"))
                    }
                    .chartLegend(position: .bottom)
                    .frame(height: 190)

                    ForEach(group.values.reversed()) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.month.formatted(.dateTime.month(.wide).year()))
                                .font(.headline)
                            HStack {
                                Text("Income")
                                Spacer()
                                Text(item.income, format: .currency(code: group.currency))
                                    .foregroundStyle(.green)
                            }
                            HStack {
                                Text("Expenses")
                                Spacer()
                                Text(item.expenses, format: .currency(code: group.currency))
                                    .foregroundStyle(.orange)
                            }
                            HStack {
                                Text("Net")
                                Spacer()
                                Text(item.net, format: .currency(code: group.currency))
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    }
                }
            }

            Section {
                Text("Only confirmed income and expenses are included. Transfers between your own accounts and imported items awaiting review are excluded. Different currencies are shown separately and are never added together.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Monthly insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
