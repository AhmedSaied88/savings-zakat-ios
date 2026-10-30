import SwiftUI

struct WalletDashboardTab: View {
    @Binding var snapshot: FinanceSnapshot
    @Binding var preferences: FinancePreferences
    let onSave: () -> Void
    let onRestore: (FinanceSnapshot) -> Bool

    private var ledger: FinanceLedger { FinanceLedger(snapshot: snapshot) }
    private var summary: MoneySummary {
        ledger.netWorth(in: "EGP", rates: preferences.exchangeRatesToEGP.mapValues { Decimal($0) })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WalletSummaryContent(summary: summary)
                }
                Section {
                    WalletAccountsContent(accounts: snapshot.accounts, ledger: ledger)
                } header: {
                    Text("Accounts")
                }
                Section("Recent activity") {
                    WalletRecentActivityContent(
                        transactions: snapshot.transactions,
                        accountName: accountName
                    )
                }
                Section("Quick overview") {
                    WalletQuickOverviewContent(
                        snapshot: $snapshot,
                        preferences: $preferences,
                        onSave: onSave,
                        onRestore: onRestore
                    )
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
                                    .accessibilityIdentifier("account-balance-\(account.name)")
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
                        let cardCurrency = card.currency ?? snapshot.accounts.first(where: { $0.id == card.linkedAccountID })?.currency ?? "EGP"
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Label(card.name, systemImage: card.kind == .credit ? "creditcard.fill" : "creditcard")
                                    .font(.headline)
                                Spacer()
                                Text("•••• \(card.lastFour ?? "----")").monospacedDigit().foregroundStyle(.secondary).accessibilityIdentifier("card-last-four")
                            }
                            Text(card.issuer ?? card.kind.rawValue.capitalized)
                                .font(.caption).foregroundStyle(.secondary)
                            if card.kind == .credit {
                                HStack(spacing: 12) {
                                    Text("Outstanding")
                                    Text((try? ledger.creditCardOutstanding(for: card.id)) ?? (card.openingOutstandingBalance ?? 0),
                                         format: .currency(code: cardCurrency))
                                        .accessibilityIdentifier("card-outstanding-\(card.name)")
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
                    .onDelete { offsets in
                        let selectedCards = offsets.map { snapshot.cards[$0] }
                        var updatedLedger = FinanceLedger(snapshot: snapshot)
                        do {
                            for card in selectedCards { try updatedLedger.removeCard(id: card.id) }
                            snapshot = updatedLedger.snapshot
                            errorMessage = nil
                            onSave()
                        } catch {
                            errorMessage = "A card with linked purchases, repayments or an opening liability cannot be deleted."
                        }
                    }
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
                    var updatedLedger = FinanceLedger(snapshot: snapshot)
                    do {
                        try updatedLedger.addCard(card)
                        snapshot = updatedLedger.snapshot
                        errorMessage = nil
                        onSave()
                    } catch {
                        errorMessage = "Could not save card. Check its currency, opening balance and account link."
                    }
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
    @State private var showAddRecurring = false
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

                Section("Recurring transactions") {
                    let rules = snapshot.recurringTransactions ?? []
                    if rules.isEmpty {
                        Text("Set up regular income or expenses such as salary, rent or subscriptions.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(rules) { rule in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(rule.title).font(.headline)
                                Spacer()
                                Text(rule.amount, format: .currency(code: rule.currency))
                                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                            }
                            HStack {
                                Text("\(rule.direction.rawValue.capitalized) · Every \(rule.interval) \(rule.frequency.rawValue)")
                                Spacer()
                                Text(rule.isEnabled ? "Enabled" : "Paused")
                                    .foregroundStyle(rule.isEnabled ? Color.green : Color.secondary)
                            }
                            .font(.caption).foregroundStyle(.secondary)
                            Text("Next: \(rule.nextDueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Button(rule.isEnabled ? "Pause" : "Resume") {
                                    guard let index = snapshot.recurringTransactions?.firstIndex(where: { $0.id == rule.id }) else { return }
                                    snapshot.recurringTransactions?[index].isEnabled.toggle()
                                    onSave()
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                                Button("Delete", role: .destructive) {
                                    snapshot.recurringTransactions?.removeAll { $0.id == rule.id }
                                    onSave()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Button {
                        showAddRecurring = true
                    } label: {
                        Label("Add recurring transaction", systemImage: "repeat").accessibilityIdentifier("add-recurring-transaction")
                    }
                    .disabled(snapshot.accounts.isEmpty)
                    Button {
                        do {
                            var ledger = FinanceLedger(snapshot: snapshot)
                            let count = try ledger.generateDueRecurringTransactions(asOf: Date())
                            snapshot = ledger.snapshot
                            onSave()
                            errorMessage = "Created \(count) due recurring transaction(s). They now affect account balances."
                        } catch {
                            errorMessage = "Could not create due recurring entries: \(error.localizedDescription)"
                        }
                    } label: {
                        Label("Create due entries", systemImage: "calendar.badge.clock").accessibilityIdentifier("create-due-recurring-entries")
                    }
                    .disabled(!rules.contains(where: { $0.isEnabled && $0.nextDueDate <= Date() }))
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
            .sheet(isPresented: $showAddRecurring) {
                RecurringTransactionEditorSheet(accounts: snapshot.accounts) { rule in
                    var ledger = FinanceLedger(snapshot: snapshot)
                    do {
                        try ledger.addRecurringRule(rule)
                        snapshot = ledger.snapshot
                        errorMessage = nil
                        onSave()
                    } catch {
                        errorMessage = "Could not save recurring transaction: \(error.localizedDescription)"
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                TransactionEditorSheet(accounts: snapshot.accounts, cards: snapshot.cards) { transaction in
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
                ImportedMessageConfirmationSheet(message: message, accounts: snapshot.accounts, cards: snapshot.cards) { transaction in
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


private struct RecurringTransactionEditorSheet: View {
    let accounts: [FinanceAccount]
    let onSave: (RecurringTransaction) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var direction = TransactionDirection.expense
    @State private var accountID: UUID?
    @State private var category = "Bills"
    @State private var frequency = RecurringFrequency.monthly
    @State private var interval = 1
    @State private var nextDueDate = Date()

    init(accounts: [FinanceAccount], onSave: @escaping (RecurringTransaction) -> Void) {
        self.accounts = accounts
        self.onSave = onSave
        _accountID = State(initialValue: accounts.first?.id)
    }

    private var selectedAccount: FinanceAccount? {
        accounts.first(where: { $0.id == accountID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction") {
                    TextField("Description", text: $title)
                    TextField("Amount", text: $amount).keyboardType(.decimalPad)
                    Picker("Type", selection: $direction) {
                        Text("Expense").tag(TransactionDirection.expense)
                        Text("Income").tag(TransactionDirection.income)
                    }
                    Picker("Account", selection: $accountID) {
                        ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Picker("Category", selection: $category) {
                        ForEach(["Food", "Transport", "Shopping", "Bills", "Housing", "Health", "Education", "Salary", "Other"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    if let selectedAccount {
                        LabeledContent("Currency", value: selectedAccount.currency)
                    }
                }
                Section("Schedule") {
                    Picker("Repeat", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) {
                            Text($0.rawValue.capitalized).tag($0)
                        }
                    }
                    Stepper("Every \(interval) interval(s)", value: $interval, in: 1...24)
                    DatePicker("First due date", selection: $nextDueDate, displayedComponents: .date)
                }
                Text("Recurring entries are not posted automatically. Use “Create due entries” when you want them added to your ledger.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("New recurring entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let accountID, let selectedAccount, let value = Decimal(string: amount), value > 0 else { return }
                        onSave(RecurringTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                    amount: value, currency: selectedAccount.currency,
                                                    direction: direction, accountID: accountID, category: category,
                                                    frequency: frequency, interval: interval, nextDueDate: nextDueDate))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              !(Decimal(string: amount).map { $0 > 0 } ?? false) || accountID == nil)
                }
            }
        }
    }
}

private struct ImportedMessageConfirmationSheet: View {
    private enum EntryKind: String, CaseIterable {
        case account = "Account transaction"
        case cardPurchase = "Credit-card purchase"
        case cardRepayment = "Credit-card repayment"
    }

    let message: ImportedMessage
    let accounts: [FinanceAccount]
    let cards: [FinanceCard]
    let onConfirm: (FinanceTransaction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var entryKind = EntryKind.account
    @State private var accountID: UUID?
    @State private var destinationAccountID: UUID?
    @State private var cardID: UUID?
    @State private var direction: TransactionDirection

    init(message: ImportedMessage, accounts: [FinanceAccount], cards: [FinanceCard],
         onConfirm: @escaping (FinanceTransaction) -> Void) {
        self.message = message
        self.accounts = accounts
        self.cards = cards
        self.onConfirm = onConfirm
        let initialAccount = accounts.first(where: { $0.currency == message.currency })
        let initialCard = cards.first(where: { card in
            card.kind == .credit &&
            (card.currency ?? accounts.first(where: { $0.id == card.linkedAccountID })?.currency ?? "EGP") == message.currency
        })
        _accountID = State(initialValue: initialAccount?.id)
        _destinationAccountID = State(initialValue: accounts.first(where: {
            $0.id != initialAccount?.id && $0.currency == message.currency
        })?.id)
        _cardID = State(initialValue: initialCard?.id)
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

    private var creditCards: [FinanceCard] {
        cards.filter { card in
            card.kind == .credit &&
            (card.currency ?? accounts.first(where: { $0.id == card.linkedAccountID })?.currency ?? "EGP") == message.currency
        }
    }

    private var selectedCard: FinanceCard? {
        creditCards.first(where: { $0.id == cardID })
    }

    private var eligiblePaymentCards: [FinanceCard] {
        guard let selectedAccount else { return [] }
        return cards.filter { card in
            card.kind == .credit &&
            (card.currency ?? accounts.first(where: { $0.id == card.linkedAccountID })?.currency ?? "EGP") == selectedAccount.currency
        }
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
                Section("Confirm transaction type") {
                    Picker("Entry type", selection: $entryKind) {
                        ForEach(EntryKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    if entryKind == .account {
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
                            Text("Transfers are only for moving money between your own accounts.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    } else if entryKind == .cardPurchase {
                        if creditCards.isEmpty {
                            Text("No credit card matches this message currency. Add a matching credit card first.")
                                .font(.footnote).foregroundStyle(.orange)
                        } else {
                            Picker("Credit card", selection: $cardID) {
                                ForEach(creditCards) { card in
                                    Text(card.name).tag(Optional(card.id))
                                }
                            }
                            Text("This records a card purchase without reducing your bank account.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Pay from account", selection: $accountID) {
                            ForEach(eligibleAccounts) { account in
                                Text(account.name).tag(Optional(account.id))
                            }
                        }
                        if eligiblePaymentCards.isEmpty {
                            Text("No matching credit card is available in this currency.")
                                .font(.footnote).foregroundStyle(.orange)
                        } else {
                            Picker("Credit card", selection: $cardID) {
                                ForEach(eligiblePaymentCards) { card in
                                    Text(card.name).tag(Optional(card.id))
                                }
                            }
                            Text("This is a transfer to the card, not another expense.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    if eligibleAccounts.isEmpty && entryKind != .cardPurchase {
                        Text("Add an account in \(message.currency ?? "the message currency") before confirming this item.")
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
                Section {
                    Button("Confirm and add to ledger") {
                        guard let amount = message.amount, let currency = message.currency else { return }
                        let transaction: FinanceTransaction
                        switch entryKind {
                        case .account:
                            guard let accountID, let selectedAccount,
                                  selectedAccount.currency == currency else { return }
                            if direction == .transfer &&
                                (destinationAccountID == nil || destinationAccountID == accountID) { return }
                            transaction = FinanceTransaction(
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
                        case .cardPurchase:
                            guard let selectedCard else { return }
                            transaction = FinanceTransaction(
                                title: message.category ?? "Credit-card purchase",
                                amount: amount,
                                currency: currency,
                                direction: .expense,
                                date: message.receivedAt,
                                source: .shortcut,
                                reviewStatus: .confirmed,
                                category: "Card purchase · \(selectedCard.name)",
                                importedMessageID: message.id,
                                cardID: selectedCard.id
                            )
                        case .cardRepayment:
                            guard let accountID, let selectedAccount, let selectedCard,
                                  selectedAccount.currency == currency else { return }
                            transaction = FinanceTransaction(
                                title: message.category ?? "Credit-card repayment",
                                amount: amount,
                                currency: currency,
                                direction: .transfer,
                                date: message.receivedAt,
                                accountID: accountID,
                                source: .shortcut,
                                reviewStatus: .confirmed,
                                category: "Card repayment · \(selectedCard.name)",
                                importedMessageID: message.id,
                                destinationCardID: selectedCard.id
                            )
                        }
                        onConfirm(transaction)
                        dismiss()
                    }
                    .disabled(
                        message.amount == nil || message.currency == nil ||
                        (entryKind == .account && (selectedAccount == nil ||
                            (direction == .transfer && (destinationAccountID == nil || destinationAccountID == accountID)))) ||
                        (entryKind == .cardPurchase && selectedCard == nil) ||
                        (entryKind == .cardRepayment && (selectedAccount == nil ||
                            !eligiblePaymentCards.contains(where: { $0.id == cardID })))
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
                if entryKind == .cardRepayment && !eligiblePaymentCards.contains(where: { $0.id == cardID }) {
                    cardID = eligiblePaymentCards.first?.id
                }
            }
            .onChange(of: entryKind) { _, newValue in
                if newValue == .cardPurchase && selectedCard == nil {
                    cardID = creditCards.first?.id
                } else if newValue == .cardRepayment && !eligiblePaymentCards.contains(where: { $0.id == cardID }) {
                    cardID = eligiblePaymentCards.first?.id
                }
            }
        }
    }
}

