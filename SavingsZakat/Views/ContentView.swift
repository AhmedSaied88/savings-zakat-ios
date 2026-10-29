import SwiftUI

struct ContentView: View {
    @AppStorage("testHoldingsJSON") private var holdingsJSON = "[]"
    @State private var holdings: [Holding] = []
    @State private var showCash = false
    @State private var showGold = false
    @State private var rates: [String: Double] = ["EGP": 1]
    @State private var goldPrices: [String: Double] = [:]
    @State private var silverPrice: Double?
    @State private var nisab = 0.0
    @State private var result: ZakatResult?

    var body: some View {
        NavigationStack {
            List {
                Section("Add asset") {
                    Button("Add cash / currency") { showCash = true }
                    Button("Add gold purchase") { showGold = true }
                }
                Section("All assets") {
                    if holdings.isEmpty { Text("No assets yet. Add a test holding to begin.") }
                    ForEach(holdings) { h in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(label(h)).font(.headline)
                            Text("Hawl start: \(h.hawlStartDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(.secondary)
                            if let due = HawlCalculator.dueDate(startDate: h.hawlStartDate) {
                                Text("Estimated anniversary: \(due.formatted(date: .long, time: .omitted))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.onDelete { offsets in holdings.remove(atOffsets: offsets); save(); calculate() }
                }
                Section("Combined zakat test") {
                    HStack {
                        Text("Nisab (EGP)")
                        TextField("Nisab", value: $nisab, format: .number).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Calculate zakat") { calculate() }.buttonStyle(.borderedProminent)
                    if let result {
                        row("Total valued assets", result.totalValuedWealthEGP)
                        row("Wealth with completed hawl", result.maturedEligibleWealthEGP)
                        row("Estimated zakat", result.zakatDueEGP)
                        if result.isProvisional {
                            ForEach(result.warnings, id: \.self) { Text($0).font(.footnote).foregroundStyle(.orange) }
                        }
                    }
                }
                Section("Manual test prices") {
                    ForEach(["SAR", "USD", "AED", "EUR", "GBP"], id: \.self) { code in
                        HStack {
                            Text("1 \(code) = EGP")
                            TextField("Rate", value: Binding(get: { rates[code] ?? 0 }, set: { rates[code] = $0 }), format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    ForEach(["24", "21", "18"], id: \.self) { carat in
                        HStack {
                            Text("Gold \(carat)K / gram")
                            TextField("EGP", value: Binding(get: { goldPrices[carat] ?? 0 }, set: { goldPrices[carat] = $0 }), format: .number)
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Text("Silver / gram")
                        TextField("EGP", value: Binding(get: { silverPrice ?? 0 }, set: { silverPrice = $0 }), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Text("Manual prices only. Missing values make the calculation provisional.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Savings & Zakat")
            .sheet(isPresented: $showCash) { CashSheet { holdings.append($0); save() } }
            .sheet(isPresented: $showGold) { GoldSheet { holdings.append($0); save() } }
            .onAppear {
                if let data = holdingsJSON.data(using: .utf8),
                   let saved = try? JSONDecoder().decode([Holding].self, from: data) { holdings = saved }
            }
        }
    }

    private func label(_ h: Holding) -> String {
        switch h.kind {
        case .cash: return "Cash · \(h.currency ?? "EGP") · \(h.amount)"
        case .gold: return "Gold · \(h.carat ?? 24)K · \(h.grams ?? h.amount) g"
        case .silver: return "Silver · \(h.grams ?? h.amount) g"
        }
    }
    private func row(_ title: String, _ value: Double) -> some View {
        HStack { Text(title); Spacer(); Text("EGP \(value, format: .number.precision(.fractionLength(2)))").bold() }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(holdings) { holdingsJSON = String(decoding: data, as: UTF8.self) }
    }
    private func calculate() {
        result = ZakatCalculator.calculate(holdings: holdings, ratesToEGP: rates, goldPricesPerGramEGP: goldPrices, silverPricePerGramEGP: silverPrice, nisabEGP: nisab, asOf: Date())
    }
}

private struct CashSheet: View {
    var onSave: (Holding) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var currency = "EGP"
    @State private var acquired = Date()
    @State private var start = Date()
    private let currencies = ["EGP", "SAR", "USD", "AED", "EUR", "GBP"]
    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount", text: $amount).keyboardType(.decimalPad)
                Picker("Currency", selection: $currency) { ForEach(currencies, id: \.self) { Text($0).tag($0) } }
                DatePicker("Date acquired", selection: $acquired, displayedComponents: .date)
                DatePicker("Hawl start", selection: $start, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add cash")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let n = Double(amount), n > 0, n.isFinite else { return }
                        onSave(Holding(id: UUID(), kind: .cash, amount: n, currency: currency, grams: nil, carat: nil, acquiredDate: acquired, hawlStartDate: start, purpose: .investment))
                        dismiss()
                    }.disabled(!(Double(amount).map { $0 > 0 && $0.isFinite } ?? false))
                }
            }
        }
    }
}

private struct GoldSheet: View {
    var onSave: (Holding) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var grams = ""
    @State private var carat = 21
    @State private var purpose = HoldingPurpose.investment
    @State private var purchased = Date()
    @State private var start = Date()
    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight (grams)", text: $grams).keyboardType(.decimalPad)
                Picker("Carat", selection: $carat) { ForEach([24, 22, 21, 18, 14], id: \.self) { Text("\($0)K").tag($0) } }
                Picker("Purpose", selection: $purpose) {
                    Text("Investment").tag(HoldingPurpose.investment)
                    Text("Personal use").tag(HoldingPurpose.personalUse)
                }
                DatePicker("Purchase date", selection: $purchased, displayedComponents: .date)
                DatePicker("Hawl start", selection: $start, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add gold")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let n = Double(grams), n > 0, n.isFinite else { return }
                        onSave(Holding(id: UUID(), kind: .gold, amount: n, currency: nil, grams: n, carat: carat, acquiredDate: purchased, hawlStartDate: start, purpose: purpose))
                        dismiss()
                    }.disabled(!(Double(grams).map { $0 > 0 && $0.isFinite } ?? false))
                }
            }
        }
    }
}
