import SwiftUI

struct ContentView: View {
    @State private var snapshot = FinanceSnapshot()
    @State private var showCash = false
    @State private var showGold = false
    @State private var showAccount = false
    @State private var showCard = false
    @State private var showLiability = false
    @State private var showTransaction = false
    @State private var rates: [String: Double] = ["EGP": 1]
    @State private var goldPrices: [String: Double] = [:]
    @State private var silverPrice: Double?
    @State private var nisab = 0.0
    @State private var result: ZakatResult?
    @State private var storageError: String?

    private let store = FinanceStore()
    private var holdings: [Holding] { snapshot.holdings }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your money, organised").font(.title3.bold())
                            Text("Accounts · spending · savings · Zakat").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "wallet.bifold").font(.title2).foregroundStyle(.blue)
                    }.padding(.vertical, 6)
                }
                Section("Accounts") {
                    if snapshot.accounts.isEmpty {
                        ContentUnavailableView("No accounts yet", systemImage: "building.columns", description: Text("Add your bank, cash or savings accounts."))
                    }
                    ForEach(snapshot.accounts) { account in
                        HStack {
                            Image(systemName: accountIcon(account.kind)).foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(account.name).font(.headline)
                                Text([account.institution, account.kind.rawValue.capitalized].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(account.openingBalance, format: .number.precision(.fractionLength(2))) \(account.currency)")
                                .font(.subheadline).monospacedDigit()
                        }
                    }.onDelete { offsets in snapshot.accounts.remove(atOffsets: offsets); save() }
                    Button { showAccount = true } label: { Label("Add account", systemImage: "plus.circle.fill") }
                }
                Section("Recent transactions") {
                    if snapshot.transactions.isEmpty {
                        Text("Transactions you add or import will appear here.").foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.transactions.sorted { $0.date > $1.date }.prefix(10)) { transaction in
                        HStack {
                            Image(systemName: transaction.direction == .income ? "arrow.down.left.circle" : transaction.direction == .transfer ? "arrow.left.arrow.right.circle" : "arrow.up.right.circle")
                                .foregroundStyle(transaction.direction == .income ? .green : .primary)
                            VStack(alignment: .leading) {
                                Text(transaction.title)
                                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(transaction.amount, format: .number.precision(.fractionLength(2))) \(transaction.currency)")
                                if transaction.reviewStatus == .needsReview {
                                    Text("Review").font(.caption2).foregroundStyle(.orange)
                                }
                            }
                        }
                    }.onDelete { offsets in
                        let sorted = snapshot.transactions.sorted { $0.date > $1.date }
                        let ids = Set(offsets.map { sorted[$0].id })
                        snapshot.transactions.removeAll { ids.contains($0.id) }
                        save()
                    }
                    Button { showTransaction = true } label: { Label("Add transaction", systemImage: "plus.circle.fill") }
                }
                Section("Cards") {
                    if snapshot.cards.isEmpty {
                        Text("Add a card to keep its label and last four digits.").foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.cards) { card in
                        Label {
                            VStack(alignment: .leading) {
                                Text(card.name)
                                Text("\(card.issuer ?? card.kind.rawValue.capitalized) · •••• \(card.lastFour ?? "----")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: card.kind == .credit ? "creditcard" : "creditcard.and.123")
                        }
                    }.onDelete { offsets in snapshot.cards.remove(atOffsets: offsets); save() }
                    Button { showCard = true } label: { Label("Add card", systemImage: "plus.circle.fill") }
                }
                Section("Loans & debts") {
                    if snapshot.liabilities.isEmpty {
                        Text("Track loans, instalments and card balances here.").foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.liabilities) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.headline)
                            Text(item.kind.rawValue.capitalized + " · " + item.currency).font(.caption).foregroundStyle(.secondary)
                            Text("\(item.outstandingAmount, format: .number.precision(.fractionLength(2))) \(item.currency)")
                        }
                    }.onDelete { offsets in snapshot.liabilities.remove(atOffsets: offsets); save() }
                    Button { showLiability = true } label: { Label("Add loan / debt", systemImage: "plus.circle.fill") }
                }
                Section("Savings & Zakat assets") {
                    Button("Add cash / currency") { showCash = true }
                    Button("Add gold purchase") { showGold = true }
                    if holdings.isEmpty { Text("No savings assets recorded yet.").foregroundStyle(.secondary) }
                    ForEach(holdings) { h in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(label(h)).font(.headline)
                            Text("Hawl start: \(h.hawlStartDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(.secondary)
                            if let due = HawlCalculator.dueDate(startDate: h.hawlStartDate) {
                                Text("Calendar anniversary: \(due.formatted(date: .long, time: .omitted))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.onDelete { offsets in snapshot.holdings.remove(atOffsets: offsets); save(); calculate() }
                }
                Section("Combined Zakat calculation") {
                    HStack {
                        Text("Nisab (EGP)")
                        TextField("Nisab", value: $nisab, format: .number).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Calculate Zakat") { calculate() }.buttonStyle(.borderedProminent)
                    if let result {
                        row("Total valued assets", result.totalValuedWealthEGP)
                        row("Wealth with completed Hawl", result.maturedEligibleWealthEGP)
                        row("Estimated Zakat", result.zakatDueEGP)
                        if result.isProvisional {
                            ForEach(result.warnings, id: \.self) { Text($0).font(.footnote).foregroundStyle(.orange) }
                        }
                    }
                    Text("Prices and exchange rates are manual at this stage. Confirm all values before relying on the result.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Manual valuation rates") {
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
                }
                if let storageError {
                    Section("Local storage") { Text(storageError).font(.footnote).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Savings & Zakat")
            .sheet(isPresented: $showAccount) {
                AccountSheet { snapshot.accounts.append($0); save() }
            }
            .sheet(isPresented: $showTransaction) {
                TransactionSheet(accounts: snapshot.accounts) { snapshot.transactions.append($0); save() }
            }
            .sheet(isPresented: $showCard) {
                CardEntrySheet(accounts: snapshot.accounts) { snapshot.cards.append($0); save() }
            }
            .sheet(isPresented: $showLiability) {
                LiabilityEntrySheet { snapshot.liabilities.append($0); save() }
            }
            .sheet(isPresented: $showCash) {
                CashSheet { snapshot.holdings.append($0); save() }
            }
            .sheet(isPresented: $showGold) {
                GoldSheet { snapshot.holdings.append($0); save() }
            }
            .onAppear(perform: load)
        }
    }

    private func accountIcon(_ kind: FinanceAccountKind) -> String {
        switch kind {
        case .bank: return "building.columns"
        case .cash: return "banknote"
        case .savings: return "safe"
        case .wallet: return "wallet.bifold"
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
    private func load() {
        do {
            snapshot = try store.load()
            storageError = nil
        } catch {
            storageError = "Could not read saved finance data: \(error.localizedDescription)"
        }
    }
    private func save() {
        do {
            try store.save(snapshot)
            storageError = nil
        } catch {
            storageError = "Could not save finance data: \(error.localizedDescription)"
        }
    }
    private func calculate() {
        result = ZakatCalculator.calculate(holdings: holdings, ratesToEGP: rates, goldPricesPerGramEGP: goldPrices, silverPricePerGramEGP: silverPrice, nisabEGP: nisab, asOf: Date())
    }
}

private struct AccountSheet: View {
    var onSave: (FinanceAccount) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var institution = ""
    @State private var kind = FinanceAccountKind.bank
    @State private var currency = "EGP"
    @State private var balance = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $name)
                TextField("Bank / institution (optional)", text: $institution)
                Picker("Type", selection: $kind) { ForEach(FinanceAccountKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }
                Picker("Currency", selection: $currency) { ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) } }
                TextField("Opening balance", text: $balance).keyboardType(.decimalPad)
            }
            .navigationTitle("New account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let value = Decimal(string: balance) ?? 0
                        onSave(FinanceAccount(name: name.trimmingCharacters(in: .whitespacesAndNewlines), institution: institution.isEmpty ? nil : institution, kind: kind, currency: currency, openingBalance: value))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TransactionSheet: View {
    var accounts: [FinanceAccount]
    var onSave: (FinanceTransaction) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var currency = "EGP"
    @State private var direction = TransactionDirection.expense
    @State private var date = Date()
    @State private var accountID: UUID?
    var body: some View {
        NavigationStack {
            Form {
                TextField("Description", text: $title)
                TextField("Amount", text: $amount).keyboardType(.decimalPad)
                Picker("Type", selection: $direction) {
                    Text("Expense").tag(TransactionDirection.expense)
                    Text("Income").tag(TransactionDirection.income)
                    Text("Transfer").tag(TransactionDirection.transfer)
                }
                Picker("Currency", selection: $currency) { ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) } }
                if !accounts.isEmpty {
                    Picker("Account", selection: $accountID) {
                        Text("Not linked").tag(UUID?.none)
                        ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle("New transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Decimal(string: amount), value > 0 else { return }
                        onSave(FinanceTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines), amount: value, currency: currency, direction: direction, date: date, accountID: accountID))
                        dismiss()
                    }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(Decimal(string: amount).map { $0 > 0 } ?? false))
                }
            }
        }
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
