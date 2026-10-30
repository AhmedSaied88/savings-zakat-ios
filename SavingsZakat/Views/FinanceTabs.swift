import SwiftUI

struct WalletDashboardTab: View {
    let snapshot: FinanceSnapshot
    let rates: [String: Double]

    private var ledger: FinanceLedger { FinanceLedger(snapshot: snapshot) }
    private var summary: MoneySummary {
        ledger.netWorth(in: "EGP", rates: rates.mapValues { Decimal($0) })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Net worth · accounts and debts").font(.subheadline).foregroundStyle(.secondary)
                        Text(summary.netWorth, format: .currency(code: "EGP"))
                            .font(.largeTitle.bold()).monospacedDigit()
                            .accessibilityLabel("Net worth \(summary.netWorth) Egyptian pounds")
                        HStack(spacing: 18) {
                            metric("Assets", summary.totalAssets, color: .blue)
                            metric("Debts", summary.totalLiabilities, color: .orange)
                        }
                        Text("This first summary excludes unvalued gold and silver holdings.")
                            .font(.caption).foregroundStyle(.secondary)
                        if summary.isProvisional {
                            Label("Some currencies need exchange rates", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.blue.opacity(0.06))
                }
                Section("Accounts") {
                    if snapshot.accounts.isEmpty {
                        ContentUnavailableView("No accounts yet", systemImage: "building.columns",
                                               description: Text("Add a bank, cash or savings account from Accounts."))
                    }
                    ForEach(snapshot.accounts) { account in
                        HStack(spacing: 12) {
                            Image(systemName: icon(for: account.kind))
                                .font(.title3).foregroundStyle(.blue).frame(width: 34, height: 34)
                                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(account.name).font(.headline)
                                Text(account.institution ?? account.kind.rawValue.capitalized)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text((try? ledger.balance(for: account.id)) ?? 0, format: .currency(code: account.currency))
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                        }
                        .padding(.vertical, 3)
                    }
                }
                Section("Recent activity") {
                    if snapshot.transactions.isEmpty {
                        Text("Your confirmed income, expenses and transfers will appear here.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.transactions.sorted { $0.date > $1.date }.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction, accountName: accountName(transaction.accountID))
                    }
                }
                Section("Quick overview") {
                    Label("\(snapshot.cards.count) cards", systemImage: "creditcard")
                    Label("\(snapshot.liabilities.count) loans and debts", systemImage: "doc.text")
                    Label("\(snapshot.holdings.count) savings and Zakat assets", systemImage: "sparkles")
                }
            }
            .navigationTitle("Wallet")
        }
    }

    private func metric(_ title: String, _ value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .currency(code: "EGP")).font(.subheadline.bold()).foregroundStyle(color)
        }
    }

    private func icon(for kind: FinanceAccountKind) -> String {
        switch kind {
        case .bank: return "building.columns"
        case .cash: return "banknote"
        case .savings: return "safe"
        case .wallet: return "wallet.bifold"
        }
    }

    private func accountName(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return snapshot.accounts.first(where: { $0.id == id })?.name
    }
}

struct AccountsCardsTab: View {
    @Binding var snapshot: FinanceSnapshot
    let onSave: () -> Void
    @State private var showNewAccount = false
    @State private var editingAccount: FinanceAccount?
    @State private var showNewCard = false
    @State private var errorMessage: String?

    private var ledger: FinanceLedger { FinanceLedger(snapshot: snapshot) }

    var body: some View {
        NavigationStack {
            List {
                Section("Bank, cash and savings accounts") {
                    if snapshot.accounts.isEmpty {
                        ContentUnavailableView("No accounts", systemImage: "building.columns",
                                               description: Text("Add your first account to start tracking balances."))
                    }
                    ForEach(snapshot.accounts) { account in
                        Button { editingAccount = account } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(account.name).font(.headline).foregroundStyle(.primary)
                                    Text([account.institution, account.kind.rawValue.capitalized].compactMap { $0 }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text((try? ledger.balance(for: account.id)) ?? account.openingBalance,
                                     format: .currency(code: account.currency))
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) { deleteAccount(account) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    Button { showNewAccount = true } label: {
                        Label("Add account", systemImage: "plus.circle.fill").frame(minHeight: 44)
                    }
                }
                Section("Cards") {
                    if snapshot.cards.isEmpty {
                        Text("Store card labels and masked digits only.").foregroundStyle(.secondary)
                    }
                    ForEach(snapshot.cards) { card in
                        let cardCurrency = snapshot.accounts.first(where: { $0.id == card.linkedAccountID })?.currency ?? "EGP"
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Label(card.name, systemImage: card.kind == .credit ? "creditcard.fill" : "creditcard")
                                    .font(.headline)
                                Spacer()
                                Text("•••• \(card.lastFour ?? "----")").monospacedDigit().foregroundStyle(.secondary)
                            }
                            Text(card.issuer ?? card.kind.rawValue.capitalized)
                                .font(.caption).foregroundStyle(.secondary)
                            if card.kind == .credit {
                                HStack(spacing: 12) {
                                    if let limit = card.creditLimit {
                                        Text("Limit: \(limit, format: .currency(code: cardCurrency))")
                                    }
                                    if let minimum = card.minimumDue {
                                        Text("Minimum: \(minimum, format: .currency(code: cardCurrency))")
                                    }
                                }.font(.caption).foregroundStyle(.secondary)
                                if let due = card.paymentDueDate {
                                    Label("Payment due \(due.formatted(date: .abbreviated, time: .omitted))",
                                          systemImage: "calendar").font(.caption).foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in snapshot.cards.remove(atOffsets: offsets); onSave() }
                    Button { showNewCard = true } label: {
                        Label("Add card", systemImage: "plus.circle.fill").frame(minHeight: 44)
                    }
                }
                if let errorMessage {
                    Section("Account action") {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Accounts & Cards")
            .sheet(isPresented: $showNewAccount) {
                AccountEditorSheet { account in
                    snapshot.accounts.append(account)
                    onSave()
                }
            }
            .sheet(item: $editingAccount) { account in
                AccountEditorSheet(account: account,
                                   currencyLocked: snapshot.transactions.contains { $0.accountID == account.id || $0.destinationAccountID == account.id }) { updated in
                    if let index = snapshot.accounts.firstIndex(where: { $0.id == updated.id }) {
                        snapshot.accounts[index] = updated
                        onSave()
                    }
                }
            }
            .sheet(isPresented: $showNewCard) {
                CardEntrySheet(accounts: snapshot.accounts) { card in
                    snapshot.cards.append(card)
                    onSave()
                }
            }
        }
    }

    private func deleteAccount(_ account: FinanceAccount) {
        var ledger = FinanceLedger(snapshot: snapshot)
        do {
            try ledger.removeAccount(id: account.id)
            snapshot = ledger.snapshot
            errorMessage = nil
            onSave()
        } catch {
            errorMessage = "This account has linked cards or transactions. Remove or reassign them before deleting it."
        }
    }
}

struct TransactionsTab: View {
    @Binding var snapshot: FinanceSnapshot
    @Binding var importedMessages: [ImportedMessage]
    let onSave: () -> Void
    let onSaveConfirmedTransaction: () -> Bool
    let onSaveImports: () -> Void
    let onRefreshImports: () -> Void
    @State private var showAdd = false
    @State private var selectedMessage: ImportedMessage?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Confirmed transactions")
                        Spacer()
                        Text("\(snapshot.transactions.filter { $0.reviewStatus == .confirmed }.count)")
                            .font(.headline).monospacedDigit()
                    }
                }
                Section("Imported bank messages · review required") {
                    let pending = importedMessages.filter { $0.state == .needsReview }
                    if pending.isEmpty {
                        Text("Bank messages imported through Shortcuts will appear here. They never change balances until you confirm them.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(pending) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.category ?? "Unrecognized bank message")
                                    .font(.headline)
                                Spacer()
                                Text(item.confidence?.rawValue.capitalized ?? "Manual review")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(item.redactedText)
                                .font(.subheadline).foregroundStyle(.secondary).lineLimit(4)
                            HStack {
                                Text(item.senderIdentifier)
                                Spacer()
                                Text(item.receivedAt.formatted(date: .abbreviated, time: .shortened))
                            }
                            .font(.caption).foregroundStyle(.secondary)
                            if let amount = item.amount, let currency = item.currency {
                                Text(amount, format: .currency(code: currency))
                                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                            } else {
                                Label("Could not safely identify the transaction. Add it manually if valid.",
                                      systemImage: "exclamationmark.triangle")
                                    .font(.caption).foregroundStyle(.orange)
                            }
                            HStack {
                                if item.amount != nil && item.direction != nil {
                                    Button("Review & confirm") { selectedMessage = item }
                                        .buttonStyle(.borderedProminent)
                                }
                                Spacer()
                                Button("Ignore", role: .destructive) {
                                    updateImportedMessage(item.id, state: .ignored, transactionID: nil)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                Section("Activity") {
                    if snapshot.transactions.isEmpty {
                        ContentUnavailableView("No transactions", systemImage: "arrow.left.arrow.right",
                                               description: Text("Add income, expenses or transfers to your ledger."))
                    }
                    ForEach(snapshot.transactions.sorted { $0.date > $1.date }) { item in
                        TransactionRow(transaction: item, accountName: accountName(item.accountID))
                            .swipeActions {
                                Button(role: .destructive) {
                                    snapshot.transactions.removeAll { $0.id == item.id }
                                    onSave()
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                }
                if let errorMessage {
                    Section("Could not save transaction") {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .refreshable { onRefreshImports() }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add transaction")
                }
            }
            .sheet(isPresented: $showAdd) {
                TransactionEditorSheet(accounts: snapshot.accounts) { transaction in
                    var ledger = FinanceLedger(snapshot: snapshot)
                    do {
                        try ledger.post(transaction)
                        snapshot = ledger.snapshot
                        errorMessage = nil
                        onSave()
                    } catch {
                        errorMessage = "Check the amount, account, currency and transfer destination. \(error.localizedDescription)"
                    }
                }
            }
            .sheet(item: $selectedMessage) { message in
                ImportedMessageConfirmationSheet(message: message, accounts: snapshot.accounts) { transaction in
                    if let existing = snapshot.transactions.first(where: { $0.importedMessageID == message.id }) {
                        updateImportedMessage(message.id, state: .confirmed, transactionID: existing.id)
                        errorMessage = nil
                        return
                    }
                    var ledger = FinanceLedger(snapshot: snapshot)
                    do {
                        try ledger.post(transaction)
                        let previousSnapshot = snapshot
                        snapshot = ledger.snapshot
                        guard onSaveConfirmedTransaction() else {
                            snapshot = previousSnapshot
                            return
                        }
                        updateImportedMessage(message.id, state: .confirmed, transactionID: transaction.id)
                        errorMessage = nil
                    } catch {
                        errorMessage = "The imported transaction could not be confirmed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func updateImportedMessage(_ id: UUID, state: ImportedMessageState, transactionID: UUID?) {
        guard let index = importedMessages.firstIndex(where: { $0.id == id }) else { return }
        importedMessages[index].state = state
        importedMessages[index].linkedTransactionID = transactionID
        onSaveImports()
    }

    private func accountName(_ id: UUID?) -> String? {
        guard let id else { return nil }
        return snapshot.accounts.first(where: { $0.id == id })?.name
    }
}

private struct ImportedMessageConfirmationSheet: View {
    let message: ImportedMessage
    let accounts: [FinanceAccount]
    let onConfirm: (FinanceTransaction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var accountID: UUID?
    @State private var destinationAccountID: UUID?
    @State private var direction: TransactionDirection

    init(message: ImportedMessage, accounts: [FinanceAccount], onConfirm: @escaping (FinanceTransaction) -> Void) {
        self.message = message
        self.accounts = accounts
        self.onConfirm = onConfirm
        let initialAccount = accounts.first(where: { $0.currency == message.currency })
        _accountID = State(initialValue: initialAccount?.id)
        _destinationAccountID = State(initialValue: accounts.first(where: {
            $0.id != initialAccount?.id && $0.currency == message.currency
        })?.id)
        _direction = State(initialValue: message.direction ?? .expense)
    }

    private var selectedAccount: FinanceAccount? {
        accounts.first(where: { $0.id == accountID })
    }

    private var eligibleAccounts: [FinanceAccount] {
        accounts.filter { $0.currency == message.currency }
    }

    private var eligibleDestinations: [FinanceAccount] {
        eligibleAccounts.filter { $0.id != accountID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Imported message") {
                    Text(message.redactedText).font(.subheadline)
                    if let amount = message.amount, let currency = message.currency {
                        LabeledContent("Amount", value: amount.formatted(.currency(code: currency)))
                    }
                    LabeledContent("Sender", value: message.senderIdentifier)
                    LabeledContent("Parser confidence", value: message.confidence?.rawValue.capitalized ?? "Unparsed")
                }
                Section("Verify transaction details") {
                    Picker("Transaction type", selection: $direction) {
                        Text("Income").tag(TransactionDirection.income)
                        Text("Expense").tag(TransactionDirection.expense)
                        Text("Transfer between my accounts").tag(TransactionDirection.transfer)
                    }
                    Picker("Account", selection: $accountID) {
                        ForEach(eligibleAccounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    if direction == .transfer {
                        Picker("Destination account", selection: $destinationAccountID) {
                            ForEach(eligibleDestinations) { account in
                                Text(account.name).tag(Optional(account.id))
                            }
                        }
                        Text("Transfers are only for moving money between your own accounts. Choose Income or Expense for an external transfer.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if eligibleAccounts.isEmpty {
                        Text("Add an account in \(message.currency ?? "the message currency") before confirming this item.")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
                Section {
                    Button("Confirm and add to ledger") {
                        guard let amount = message.amount,
                              let currency = message.currency,
                              let accountID,
                              let selectedAccount,
                              selectedAccount.currency == currency else { return }
                        let transaction = FinanceTransaction(
                            title: message.category ?? "Bank transaction",
                            amount: amount,
                            currency: currency,
                            direction: direction,
                            date: message.receivedAt,
                            accountID: accountID,
                            destinationAccountID: direction == .transfer ? destinationAccountID : nil,
                            source: .shortcut,
                            reviewStatus: .confirmed,
                            category: message.category ?? "Other",
                            importedMessageID: message.id
                        )
                        onConfirm(transaction)
                        dismiss()
                    }
                    .disabled(
                        message.amount == nil ||
                        message.currency == nil ||
                        selectedAccount == nil ||
                        (direction == .transfer && (destinationAccountID == nil || destinationAccountID == accountID))
                    )
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Confirm bank message")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: accountID) { _, newValue in
                if destinationAccountID == newValue || !eligibleDestinations.contains(where: { $0.id == destinationAccountID }) {
                    destinationAccountID = eligibleAccounts.first(where: { $0.id != newValue })?.id
                }
            }
        }
    }
}

struct DebtsTab: View {
    @Binding var snapshot: FinanceSnapshot
    let onSave: () -> Void
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section("Recorded debt by currency") {
                    let groups = Dictionary(grouping: snapshot.liabilities, by: \.currency)
                    ForEach(groups.keys.sorted(), id: \.self) { currency in
                        let total = groups[currency, default: []].reduce(Decimal.zero) { $0 + $1.outstandingAmount }
                        HStack {
                            Text(currency)
                            Spacer()
                            Text(total, format: .currency(code: currency)).font(.headline).monospacedDigit()
                        }
                    }
                    Text("Different currencies are kept separate; exchange rates are not assumed here.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Loans, instalments and card balances") {
                    if snapshot.liabilities.isEmpty {
                        ContentUnavailableView("No debts recorded", systemImage: "checkmark.circle",
                                               description: Text("Add a loan, instalment or credit-card balance."))
                    }
                    ForEach(snapshot.liabilities) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.name).font(.headline)
                            HStack {
                                Text(item.kind.rawValue.capitalized)
                                Spacer()
                                Text(item.outstandingAmount, format: .currency(code: item.currency))
                                    .font(.subheadline.bold()).monospacedDigit()
                            }.font(.caption)
                            if let due = item.dueDate {
                                Label("Due \(due.formatted(date: .abbreviated, time: .omitted))",
                                      systemImage: "calendar").font(.caption).foregroundStyle(.orange)
                            }
                        }.padding(.vertical, 4)
                    }
                    .onDelete { offsets in snapshot.liabilities.remove(atOffsets: offsets); onSave() }
                    Button { showAdd = true } label: {
                        Label("Add loan / debt", systemImage: "plus.circle.fill").frame(minHeight: 44)
                    }
                }
            }
            .navigationTitle("Debts")
            .sheet(isPresented: $showAdd) {
                LiabilityEntrySheet { liability in
                    var ledger = FinanceLedger(snapshot: snapshot)
                    do {
                        try ledger.addLiability(liability)
                        snapshot = ledger.snapshot
                        onSave()
                    } catch { }
                }
            }
        }
    }
}

struct AssetsZakatTab: View {
    @Binding var snapshot: FinanceSnapshot
    let onSave: () -> Void
    @Binding var rates: [String: Double]
    @State private var goldPrices: [String: Double] = [:]
    @State private var silverPrice: Double?
    @State private var nisab = 0.0
    @State private var result: ZakatResult?
    @State private var editingHolding: Holding?
    @State private var editorKind: HoldingKind = .cash
    @State private var showHoldingEditor = false
    @State private var assetError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Savings and Zakat assets") {
                    if snapshot.holdings.isEmpty {
                        ContentUnavailableView("No assets recorded", systemImage: "sparkles",
                                               description: Text("Add cash, gold, silver or a manual investment."))
                    }
                    ForEach(snapshot.holdings) { holding in
                        Button {
                            editingHolding = holding
                            editorKind = holding.kind
                            showHoldingEditor = true
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(label(holding)).font(.headline).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                                }
                                Text("Acquired: \(holding.acquiredDate.formatted(date: .abbreviated, time: .omitted)) · Hawl starts: \(holding.hawlStartDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(.secondary)
                                if let due = HawlCalculator.dueDateResult(startDate: holding.hawlStartDate) {
                                    let days = cairoDayDifference(from: Date(), to: due.date)
                                    HStack(spacing: 6) {
                                        Text((due.status == .officiallyConfirmed ? "Confirmed" : "Estimated") + " Hawl: " + due.date.formatted(date: .abbreviated, time: .omitted))
                                        Text(days >= 0 ? "· \(days) days left" : "· Matured")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(due.status == .officiallyConfirmed ? Color.secondary : Color.orange)
                                }
                                if let value = estimatedValueEGP(for: holding) {
                                    Text(value, format: .currency(code: "EGP"))
                                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                } else {
                                    Text("Valuation needed")
                                        .font(.caption).foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 5)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit asset details")
                        .swipeActions {
                            Button(role: .destructive) { deleteHolding(holding) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    ForEach(HoldingKind.allCases, id: \.self) { kind in
                        Button {
                            editingHolding = nil
                            editorKind = kind
                            showHoldingEditor = true
                        } label: {
                            Label(addTitle(for: kind), systemImage: addIcon(for: kind))
                                .frame(minHeight: 44)
                        }
                    }
                    if let assetError {
                        Text(assetError).font(.footnote).foregroundStyle(.red)
                    }
                }
                Section("Combined Zakat calculation") {
                    HStack {
                        Text("Nisab (EGP)")
                        TextField("Nisab", value: $nisab, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Button("Calculate Zakat") { calculate() }.buttonStyle(.borderedProminent)
                    if let result {
                        valueRow("Total valued assets", result.totalValuedWealthEGP)
                        valueRow("Completed-Hawl wealth", result.maturedEligibleWealthEGP)
                        valueRow("Estimated Zakat", result.zakatDueEGP)
                        if result.isProvisional {
                            ForEach(result.warnings, id: \.self) {
                                Text($0).font(.footnote).foregroundStyle(.orange)
                            }
                        }
                    }
                    Text("Confirm all prices, rates and religious calculation settings before relying on the result.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Manual valuation rates") {
                    ForEach(["SAR", "USD", "AED", "EUR", "GBP"], id: \.self) { code in
                        HStack {
                            Text("1 \(code) = EGP")
                            TextField("Rate", value: Binding(get: { rates[code] ?? 0 }, set: { rates[code] = $0 }),
                                      format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    ForEach(["24", "22", "21", "18", "14"], id: \.self) { carat in
                        HStack {
                            Text("Gold \(carat)K / gram")
                            TextField("EGP", value: Binding(get: { goldPrices[carat] ?? 0 }, set: { goldPrices[carat] = $0 }),
                                      format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Text("Silver / gram (999)")
                        TextField("EGP", value: Binding(get: { silverPrice ?? 0 }, set: { silverPrice = $0 }),
                                  format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Savings & Zakat")
            .sheet(isPresented: $showHoldingEditor) {
                HoldingEditorSheet(holding: editingHolding, defaultKind: editorKind) { updated in
                    var ledger = AssetLedger(holdings: snapshot.holdings)
                    do {
                        if snapshot.holdings.contains(where: { $0.id == updated.id }) {
                            try ledger.update(updated)
                        } else {
                            try ledger.add(updated)
                        }
                        snapshot.holdings = ledger.holdings
                        assetError = nil
                        onSave()
                        calculate()
                    } catch {
                        assetError = validationMessage(for: error)
                    }
                }
            }
        }
    }

    private func label(_ holding: Holding) -> String {
        switch holding.kind {
        case .cash:
            return "Cash · \(holding.currency ?? "EGP") · \(holding.amount)"
        case .gold:
            return "Gold · \(holding.carat ?? 24)K · \(holding.grams ?? holding.amount) g"
        case .silver:
            return "Silver · \(holding.purity ?? 999)‰ · \(holding.grams ?? holding.amount) g"
        case .investment:
            return "\(holding.name ?? "Investment") · \(holding.currency ?? "EGP") · \(holding.amount)"
        }
    }

    private func addTitle(for kind: HoldingKind) -> String {
        switch kind {
        case .cash: return "Add cash / currency"
        case .gold: return "Add gold"
        case .silver: return "Add silver"
        case .investment: return "Add manual investment"
        }
    }

    private func addIcon(for kind: HoldingKind) -> String {
        switch kind {
        case .cash: return "banknote"
        case .gold: return "circle.lefthalf.filled"
        case .silver: return "circle"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }

    private func estimatedValueEGP(for holding: Holding) -> Double? {
        switch holding.kind {
        case .cash, .investment:
            guard let currency = holding.currency, let rate = rates[currency], rate.isFinite, rate > 0 else { return nil }
            return holding.amount * rate
        case .gold:
            guard let price = goldPrices[String(holding.carat ?? 24)], price.isFinite, price > 0 else { return nil }
            return (holding.grams ?? holding.amount) * price
        case .silver:
            guard let price = silverPrice, price.isFinite, price > 0 else { return nil }
            return (holding.grams ?? holding.amount) * price * Double(holding.purity ?? 999) / 1000
        }
    }

    private func cairoDayDifference(from start: Date, to end: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: start),
                                       to: calendar.startOfDay(for: end)).day ?? 0
    }

    private func hijriLabel(for date: Date, status: HijriDateStatus) -> String {
        guard let hijri = EgyptianCalendarRepository.makeCalendar().convert(date) else {
            return "Hijri equivalent unavailable"
        }
        let monthNames = ["", "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
                          "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
                          "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
        let month = (1...12).contains(hijri.hijriMonth) ? monthNames[hijri.hijriMonth] : "Month \\(hijri.hijriMonth)"
        if status == .officiallyConfirmed && hijri.status == .officiallyConfirmed {
            return "Egyptian Hijri \\(hijri.hijriDay) \\(month) \\(hijri.hijriYear) (Confirmed)"
        }
        return "Hijri estimate \\(hijri.hijriDay) \\(month) \\(hijri.hijriYear) (not official Egyptian date)"
    }

    private func valueRow(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("EGP \(value, format: .number.precision(.fractionLength(2)))").bold()
        }
    }

    private func deleteHolding(_ holding: Holding) {
        var ledger = AssetLedger(holdings: snapshot.holdings)
        do {
            try ledger.delete(id: holding.id)
            snapshot.holdings = ledger.holdings
            assetError = nil
            onSave()
            calculate()
        } catch {
            assetError = validationMessage(for: error)
        }
    }

    private func validationMessage(for error: Error) -> String {
        guard let error = error as? AssetLedger.AssetError else { return "Could not save this asset." }
        switch error {
        case .invalidAmount: return "Enter a valid amount or weight greater than zero."
        case .invalidCurrency: return "Choose a valid three-letter currency."
        case .invalidDates: return "Acquisition and Hawl dates must be valid and Hawl cannot start before acquisition."
        case .invalidGoldCarat: return "Choose a supported gold carat."
        case .invalidSilverPurity: return "Silver purity must be between 800 and 999."
        case .missingInvestmentName: return "Enter a name for this investment."
        case .duplicateHolding: return "This asset already exists."
        case .holdingNotFound: return "This asset could not be found."
        }
    }

    private func calculate() {
        result = ZakatCalculator.calculate(holdings: snapshot.holdings, ratesToEGP: rates,
                                           goldPricesPerGramEGP: goldPrices, silverPricePerGramEGP: silverPrice,
                                           nisabEGP: nisab, asOf: Date())
    }
}

private struct HoldingEditorSheet: View {
    let holding: Holding?
    let defaultKind: HoldingKind
    let onSave: (Holding) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: HoldingKind
    @State private var name: String
    @State private var amount: String
    @State private var currency: String
    @State private var carat: Int
    @State private var purity: Int
    @State private var purpose: HoldingPurpose
    @State private var acquiredDate: Date
    @State private var hawlStartDate: Date

    init(holding: Holding?, defaultKind: HoldingKind, onSave: @escaping (Holding) -> Void) {
        self.holding = holding
        self.defaultKind = defaultKind
        self.onSave = onSave
        _kind = State(initialValue: holding?.kind ?? defaultKind)
        _name = State(initialValue: holding?.name ?? "")
        let initialAmount = holding.map {
            ($0.kind == .gold || $0.kind == .silver) ? ($0.grams ?? $0.amount) : $0.amount
        }
        _amount = State(initialValue: initialAmount.map { String($0) } ?? "")
        _currency = State(initialValue: holding?.currency ?? "EGP")
        _carat = State(initialValue: holding?.carat ?? 21)
        _purity = State(initialValue: holding?.purity ?? 999)
        _purpose = State(initialValue: holding?.purpose ?? .investment)
        _acquiredDate = State(initialValue: holding?.acquiredDate ?? Date())
        _hawlStartDate = State(initialValue: holding?.hawlStartDate ?? Date())
    }

    private func hijriDescription(for date: Date) -> String {
        guard let hijri = EgyptianCalendarRepository.makeCalendar().convert(date) else {
            return "Hijri equivalent unavailable"
        }
        let monthNames = ["", "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
                          "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
                          "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
        let month = (1...12).contains(hijri.hijriMonth) ? monthNames[hijri.hijriMonth] : "Month \\(hijri.hijriMonth)"
        if hijri.status == .officiallyConfirmed {
            return "Egyptian Hijri date: \\(hijri.hijriDay) \\(month) \\(hijri.hijriYear) · Confirmed"
        }
        return "Hijri estimate: \\(hijri.hijriDay) \\(month) \\(hijri.hijriYear) · Not an official Egyptian date"
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Asset type", selection: $kind) {
                    ForEach(HoldingKind.allCases, id: \.self) { item in
                        Text(item.rawValue.capitalized).tag(item)
                    }
                }
                if kind == .investment {
                    TextField("Investment name", text: $name)
                }
                TextField(kind == .gold || kind == .silver ? "Weight (grams)" : "Amount", text: $amount)
                    .keyboardType(.decimalPad)
                if kind == .cash || kind == .investment {
                    Picker("Currency", selection: $currency) {
                        ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }
                if kind == .gold {
                    Picker("Carat", selection: $carat) {
                        ForEach([24, 22, 21, 18, 14], id: \.self) { Text("\($0)K").tag($0) }
                    }
                    Picker("Purpose", selection: $purpose) {
                        Text("Investment").tag(HoldingPurpose.investment)
                        Text("Personal use").tag(HoldingPurpose.personalUse)
                    }
                }
                if kind == .silver {
                    Picker("Purity", selection: $purity) {
                        ForEach([999, 925, 900, 800], id: \.self) { Text("\($0)‰").tag($0) }
                    }
                }
                DatePicker("Acquisition date (Gregorian)", selection: $acquiredDate, in: ...Date(), displayedComponents: .date)
                Text(hijriDescription(for: acquiredDate))
                    .font(.footnote).foregroundStyle(.secondary)
                DatePicker("Hawl start (Gregorian)", selection: $hawlStartDate,
                           in: acquiredDate...Date(), displayedComponents: .date)
                Text(hijriDescription(for: hawlStartDate))
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Gregorian civil dates are used (Africa/Cairo). Hijri equivalents are Confirmed only when covered by Egyptian Dar Al-Ifta announcements; otherwise they are Estimated.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle(holding == nil ? "Add asset" : "Edit asset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(amount), value.isFinite, value > 0 else { return }
                        let isMetal = kind == .gold || kind == .silver
                        let updated = Holding(
                            id: holding?.id ?? UUID(),
                            kind: kind,
                            amount: value,
                            currency: (kind == .cash || kind == .investment) ? currency : nil,
                            grams: isMetal ? value : nil,
                            carat: kind == .gold ? carat : nil,
                            acquiredDate: acquiredDate,
                            hawlStartDate: hawlStartDate,
                            purpose: kind == .gold ? purpose : .investment,
                            name: (kind == .investment || kind == .silver) ? name : nil,
                            purity: kind == .silver ? purity : nil
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(!(Double(amount).map { $0.isFinite && $0 > 0 } ?? false) ||
                              (kind == .investment && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                }
            }
            .onChange(of: acquiredDate) { _, newValue in
                if hawlStartDate < newValue { hawlStartDate = newValue }
            }
        }
    }
}

private struct TransactionRow: View {
    let transaction: FinanceTransaction
    let accountName: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.direction == .income ? "arrow.down.left.circle.fill" :
                    transaction.direction == .transfer ? "arrow.left.arrow.right.circle" : "arrow.up.right.circle.fill")
                .font(.title3)
                .foregroundStyle(transaction.direction == .income ? .green :
                                    transaction.direction == .expense ? .orange : .blue)
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title).font(.headline)
                Text([transaction.category, accountName, transaction.date.formatted(date: .abbreviated, time: .omitted)]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
                if transaction.reviewStatus == .needsReview {
                    Text("Needs review").font(.caption2).foregroundStyle(.orange)
                }
            }
            Spacer()
            Text(transaction.amount, format: .currency(code: transaction.currency))
                .font(.subheadline.weight(.semibold)).monospacedDigit()
        }
        .padding(.vertical, 3)
    }
}

private struct AccountEditorSheet: View {
    let account: FinanceAccount?
    let currencyLocked: Bool
    let onSave: (FinanceAccount) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var institution: String
    @State private var kind: FinanceAccountKind
    @State private var currency: String
    @State private var balance: String

    init(account: FinanceAccount? = nil, currencyLocked: Bool = false, onSave: @escaping (FinanceAccount) -> Void) {
        self.account = account
        self.currencyLocked = currencyLocked
        self.onSave = onSave
        _name = State(initialValue: account?.name ?? "")
        _institution = State(initialValue: account?.institution ?? "")
        _kind = State(initialValue: account?.kind ?? .bank)
        _currency = State(initialValue: account?.currency ?? "EGP")
        _balance = State(initialValue: account.map { NSDecimalNumber(decimal: $0.openingBalance).stringValue } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $name)
                TextField("Bank / institution (optional)", text: $institution)
                Picker("Type", selection: $kind) {
                    ForEach(FinanceAccountKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                Picker("Currency", selection: $currency) {
                    ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                }
                .disabled(currencyLocked)
                if currencyLocked {
                    Text("Currency cannot be changed while this account has transactions.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                TextField("Opening balance", text: $balance).keyboardType(.decimalPad)
            }
            .navigationTitle(account == nil ? "Add account" : "Edit account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = Decimal(string: balance) ?? account?.openingBalance ?? 0
                        onSave(FinanceAccount(id: account?.id ?? UUID(), name: trimmed,
                                              institution: institution.isEmpty ? nil : institution,
                                              kind: kind, currency: currency, openingBalance: value,
                                              isArchived: account?.isArchived ?? false))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TransactionEditorSheet: View {
    let accounts: [FinanceAccount]
    let onSave: (FinanceTransaction) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var direction = TransactionDirection.expense
    @State private var date = Date()
    @State private var accountID: UUID?
    @State private var destinationAccountID: UUID?
    @State private var category = "Shopping"

    private let categories = ["Food", "Transport", "Shopping", "Bills", "Housing", "Health", "Education", "Salary", "Other"]

    init(accounts: [FinanceAccount], onSave: @escaping (FinanceTransaction) -> Void) {
        self.accounts = accounts
        self.onSave = onSave
        let firstAccount = accounts.first
        _accountID = State(initialValue: firstAccount?.id)
        _destinationAccountID = State(initialValue: accounts.first(where: {
            $0.id != firstAccount?.id && $0.currency == firstAccount?.currency
        })?.id)
    }

    private var selectedAccount: FinanceAccount? {
        accounts.first(where: { $0.id == accountID })
    }

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
                if !accounts.isEmpty {
                    Picker("From account", selection: $accountID) {
                        ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
                    }
                    if direction == .transfer {
                        Picker("To account", selection: $destinationAccountID) {
                            ForEach(accounts.filter { $0.id != accountID && $0.currency == selectedAccount?.currency }) {
                            Text($0.name).tag(Optional($0.id))
                        }
                        }
                    } else {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    if let selectedAccount {
                        LabeledContent("Currency", value: selectedAccount.currency)
                    }
                } else {
                    ContentUnavailableView("Add an account first", systemImage: "building.columns",
                                           description: Text("Transactions must be linked to an account."))
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle("Add transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let accountID, let selectedAccount,
                              let value = Decimal(string: amount), value > 0 else { return }
                        if direction == .transfer && (destinationAccountID == nil || destinationAccountID == accountID) { return }
                        let item = FinanceTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      amount: value, currency: selectedAccount.currency,
                                                      direction: direction, date: date, accountID: accountID,
                                                      destinationAccountID: direction == .transfer ? destinationAccountID : nil,
                                                      category: direction == .transfer ? "Transfer" : category)
                        onSave(item)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              !(Decimal(string: amount).map { $0 > 0 } ?? false) ||
                              accounts.isEmpty || accountID == nil ||
                              (direction == .transfer && (destinationAccountID == nil || destinationAccountID == accountID)))
                }
            }
            .onChange(of: accountID) { _, newValue in
                let newCurrency = accounts.first(where: { $0.id == newValue })?.currency
                if destinationAccountID == newValue ||
                    accounts.first(where: { $0.id == destinationAccountID })?.currency != newCurrency {
                    destinationAccountID = accounts.first(where: {
                        $0.id != newValue && $0.currency == newCurrency
                    })?.id
                }
            }
        }
    }
}

private struct CashHoldingEntry: View {
    let onSave: (Holding) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var currency = "EGP"
    @State private var acquired = Date()
    @State private var hawlStart = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount", text: $amount).keyboardType(.decimalPad)
                Picker("Currency", selection: $currency) {
                    ForEach(["EGP", "SAR", "USD", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                }
                DatePicker("Acquired", selection: $acquired, displayedComponents: .date)
                DatePicker("Hawl start", selection: $hawlStart, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add cash")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(amount), value > 0, value.isFinite else { return }
                        onSave(Holding(id: UUID(), kind: .cash, amount: value, currency: currency, grams: nil, carat: nil,
                                       acquiredDate: acquired, hawlStartDate: hawlStart, purpose: .investment))
                        dismiss()
                    }.disabled(!(Double(amount).map { $0 > 0 && $0.isFinite } ?? false))
                }
            }
        }
    }
}

private struct GoldHoldingEntry: View {
    let onSave: (Holding) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var grams = ""
    @State private var carat = 21
    @State private var purpose = HoldingPurpose.investment
    @State private var acquired = Date()
    @State private var hawlStart = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight (grams)", text: $grams).keyboardType(.decimalPad)
                Picker("Carat", selection: $carat) {
                    ForEach([24, 22, 21, 18, 14], id: \.self) { Text("\($0)K").tag($0) }
                }
                Picker("Purpose", selection: $purpose) {
                    Text("Investment").tag(HoldingPurpose.investment)
                    Text("Personal use").tag(HoldingPurpose.personalUse)
                }
                DatePicker("Purchase date", selection: $acquired, displayedComponents: .date)
                DatePicker("Hawl start", selection: $hawlStart, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add gold")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(grams), value > 0, value.isFinite else { return }
                        onSave(Holding(id: UUID(), kind: .gold, amount: value, currency: nil, grams: value, carat: carat,
                                       acquiredDate: acquired, hawlStartDate: hawlStart, purpose: purpose))
                        dismiss()
                    }.disabled(!(Double(grams).map { $0 > 0 && $0.isFinite } ?? false))
                }
            }
        }
    }
}

private struct SilverHoldingEntry: View {
    let onSave: (Holding) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var grams = ""
    @State private var acquired = Date()
    @State private var hawlStart = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Weight (grams)", text: $grams).keyboardType(.decimalPad)
                DatePicker("Purchase date", selection: $acquired, displayedComponents: .date)
                DatePicker("Hawl start", selection: $hawlStart, in: ...Date(), displayedComponents: .date)
            }
            .navigationTitle("Add silver")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(grams), value > 0, value.isFinite else { return }
                        onSave(Holding(id: UUID(), kind: .silver, amount: value, currency: nil, grams: value, carat: nil,
                                       acquiredDate: acquired, hawlStartDate: hawlStart, purpose: .investment))
                        dismiss()
                    }.disabled(!(Double(grams).map { $0 > 0 && $0.isFinite } ?? false))
                }
            }
        }
    }
}
