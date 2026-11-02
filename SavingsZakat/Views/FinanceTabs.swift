import SwiftUI
import UIKit

/// Shared palette for the native finance interface. Light-mode values preserve
/// the selected blue/violet/gold direction; dark-mode values are brighter so
/// the same semantic roles remain legible on dark system surfaces.
enum FinancePalette {
    static let royalBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.52, green: 0.68, blue: 1.00, alpha: 1)
            : UIColor(red: 0.12, green: 0.34, blue: 0.78, alpha: 1)
    })
    static let paleBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.15, blue: 0.25, alpha: 1)
            : UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1)
    })
    static let violet = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.76, green: 0.68, blue: 1.00, alpha: 1)
            : UIColor(red: 0.43, green: 0.32, blue: 0.72, alpha: 1)
    })
    static let gold = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.80, blue: 0.40, alpha: 1)
            : UIColor(red: 0.68, green: 0.46, blue: 0.08, alpha: 1)
    })
    // Status colors are intentionally darker in Light Mode and brighter in
    // Dark Mode so small labels remain readable on native grouped surfaces.
    static let income = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.86, blue: 0.63, alpha: 1)
            : UIColor(red: 0.09, green: 0.42, blue: 0.27, alpha: 1)
    })
    static let expense = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.70, blue: 0.42, alpha: 1)
            : UIColor(red: 0.60, green: 0.30, blue: 0.00, alpha: 1)
    })
    static let warning = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.79, blue: 0.50, alpha: 1)
            : UIColor(red: 0.54, green: 0.29, blue: 0.00, alpha: 1)
    })
    static let danger = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.54, blue: 0.50, alpha: 1)
            : UIColor(red: 0.71, green: 0.14, blue: 0.09, alpha: 1)
    })
    /// Native grouped surfaces keep every tab visually aligned with iOS while
    /// retaining the product's blue/violet/gold semantic accents.
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let whiteSurface = Color(uiColor: .systemBackground)
    static let groupedSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator)
}

extension View {
    /// Shared background and accent treatment for every finance list and form.
    func financeScreenSurface() -> some View {
        self
            .scrollContentBackground(.hidden)
            // Keep the grouped canvas visible behind both the navigation bar
            // and the status-bar safe area on every primary and form screen.
            .background(FinancePalette.canvas.ignoresSafeArea())
            .toolbarBackground(FinancePalette.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(FinancePalette.royalBlue)
    }
}

struct WalletDashboardTab: View {
    @Binding var snapshot: FinanceSnapshot
    @Binding var preferences: FinancePreferences
    let onSave: () -> Void
    let onRestore: (FinanceSnapshot) -> Bool

    @State private var showAddTransaction = false
    @State private var showAddAccount = false
    @State private var showAddAsset = false
    @State private var quickAddError: String?

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
                    WalletQuickOverviewContent(snapshot: $snapshot)
                    NavigationLink {
                        FinanceInsightsView(snapshot: snapshot)
                    } label: {
                        Label("Monthly income & expenses", systemImage: "chart.bar")
                    }
                    .accessibilityIdentifier("wallet-insights-link")

                    NavigationLink {
                        SettingsHomeView(
                            snapshot: $snapshot,
                            preferences: $preferences,
                            onSave: onSave,
                            onRestore: onRestore
                        )
                    } label: {
                        Label("Settings & backup", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("wallet-settings-link")
                }
            }
            .listStyle(.insetGrouped)
            .financeScreenSurface()
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddTransaction = true
                        } label: {
                            Label("Transaction", systemImage: "arrow.left.arrow.right")
                        }
                        .accessibilityIdentifier("wallet-quick-add-transaction")

                        Button {
                            showAddAccount = true
                        } label: {
                            Label("Account", systemImage: "building.columns")
                        }
                        .accessibilityIdentifier("wallet-quick-add-account")

                        Button {
                            showAddAsset = true
                        } label: {
                            Label("Savings asset", systemImage: "sparkles")
                        }
                        .accessibilityIdentifier("wallet-quick-add-asset")
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Quick add")
                    .accessibilityHint("Add a transaction, account or savings asset")
                    .accessibilityIdentifier("wallet-quick-add")
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                TransactionEditorSheet(accounts: snapshot.accounts, cards: snapshot.cards) { transaction in
                    var updatedLedger = FinanceLedger(snapshot: snapshot)
                    do {
                        try updatedLedger.post(transaction)
                        snapshot = updatedLedger.snapshot
                        quickAddError = nil
                        onSave()
                    } catch {
                        quickAddError = "Could not add transaction. Check the amount, account, currency and transfer destination."
                    }
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AccountEditorSheet { account in
                    snapshot.accounts.append(account)
                    quickAddError = nil
                    onSave()
                }
            }
            .sheet(isPresented: $showAddAsset) {
                HoldingEditorSheet(holding: nil, defaultKind: .cash) { holding in
                    var updatedLedger = AssetLedger(holdings: snapshot.holdings)
                    do {
                        try updatedLedger.add(holding)
                        snapshot.holdings = updatedLedger.holdings
                        quickAddError = nil
                        onSave()
                    } catch {
                        quickAddError = "Could not add this asset. Check its amount, currency, weight and dates."
                    }
                }
            }
            .alert("Could not add item", isPresented: Binding(
                get: { quickAddError != nil },
                set: { if !$0 { quickAddError = nil } }
            )) {
                Button("OK", role: .cancel) { quickAddError = nil }
            } message: {
                Text(quickAddError ?? "An unknown error occurred.")
            }
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
    @State private var editingCard: FinanceCard?
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
                        .accessibilityHint("Edit account details")
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
                        let paymentDueDescription = card.paymentDueDate.map {
                            "Payment due \($0.formatted(date: .abbreviated, time: .omitted))"
                        }
                        let outstandingDescription = card.kind == .credit
                            ? "Outstanding \(((try? ledger.creditCardOutstanding(for: card.id)) ?? (card.openingOutstandingBalance ?? 0)).formatted(.currency(code: cardCurrency)))"
                            : nil
                        let maskedDigitsDescription = "Card ending in \(card.lastFour ?? "not provided")"
                        let limitDescription = card.creditLimit.map { "Limit \($0.formatted(.currency(code: cardCurrency)))" }
                        let minimumDescription = card.minimumDue.map { "Minimum due \($0.formatted(.currency(code: cardCurrency)))" }
                        Button { editingCard = card } label: {
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
                                            .foregroundStyle(FinancePalette.violet)
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
                                              systemImage: "calendar")
                                            .font(.caption).foregroundStyle(FinancePalette.warning)
                                            .accessibilityIdentifier("card-payment-due-\(card.name)")
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        // Keep the card row as one clear VoiceOver target while retaining
                        // the due-date description in its accessible label.
                        .frame(minHeight: 44)
                        .accessibilityLabel(([card.name, card.kind.rawValue.capitalized, maskedDigitsDescription,
                            outstandingDescription, limitDescription, minimumDescription, paymentDueDescription]
                            .compactMap { $0 }).joined(separator: ", "))
                        .accessibilityHint("Edit card details")
                        .accessibilityIdentifier("card-row-\(card.name)")
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
                        Text(errorMessage).font(.footnote).foregroundStyle(FinancePalette.danger)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .financeScreenSurface()
            .navigationTitle("Accounts & Cards")
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(item: $editingCard) { card in
                CardEntrySheet(
                    card: card,
                    accounts: snapshot.accounts,
                    currencyLocked: snapshot.transactions.contains {
                        $0.cardID == card.id || $0.destinationCardID == card.id
                    },
                    currentOutstandingBalance: (try? ledger.creditCardOutstanding(for: card.id)) ?? 0
                ) { updated in
                    guard let index = snapshot.cards.firstIndex(where: { $0.id == updated.id }) else { return }
                    let hasActivity = snapshot.transactions.contains {
                        $0.cardID == card.id || $0.destinationCardID == card.id
                    }
                    let linkedAccountMatches = updated.linkedAccountID == nil ||
                        snapshot.accounts.first(where: { $0.id == updated.linkedAccountID })?.currency == (updated.currency ?? "EGP")
                    let existingCurrency = card.currency
                        ?? snapshot.accounts.first(where: { $0.id == card.linkedAccountID })?.currency
                        ?? "EGP"
                    guard linkedAccountMatches,
                          (!hasActivity || updated.currency == existingCurrency),
                          updated.openingOutstandingBalance.map({ $0 >= 0 }) ?? true,
                          updated.minimumDue.map({ $0 >= 0 }) ?? true,
                          updated.creditLimit.map({ $0 >= 0 }) ?? true else {
                        errorMessage = "Could not update card. Currency and balances must remain consistent with existing activity."
                        return
                    }
                    snapshot.cards[index] = updated
                    errorMessage = nil
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
                            .fixedSize(horizontal: false, vertical: true)
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
                                    .font(.caption).foregroundStyle(FinancePalette.warning)
                            }
                            HStack {
                                if item.amount != nil && item.direction != nil {
                                    Button("Review & confirm") { selectedMessage = item }
                                        .buttonStyle(.borderedProminent)
                                        .frame(minHeight: 44)
                                }
                                Spacer()
                                Button("Ignore", role: .destructive) {
                                    updateImportedMessage(item.id, state: .ignored, transactionID: nil)
                                }
                                .buttonStyle(.bordered)
                                .frame(minHeight: 44)
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
                                    .foregroundStyle(rule.isEnabled ? FinancePalette.income : Color.secondary)
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
                                .frame(minHeight: 44)
                                Spacer()
                                Button("Delete", role: .destructive) {
                                    snapshot.recurringTransactions?.removeAll { $0.id == rule.id }
                                    onSave()
                                }
                                .buttonStyle(.bordered)
                                .frame(minHeight: 44)
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
                        Text(errorMessage).font(.footnote).foregroundStyle(FinancePalette.danger)
                    }
                }
            }
            .refreshable { onRefreshImports() }
            .listStyle(.insetGrouped)
            .financeScreenSurface()
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                        .accessibilityLabel("Add transaction")
                        .accessibilityHint("Create an income, expense or transfer entry")
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
            .financeScreenSurface()

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
                                .font(.footnote).foregroundStyle(FinancePalette.warning)
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
                                .font(.footnote).foregroundStyle(FinancePalette.warning)
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
                            .font(.footnote).foregroundStyle(FinancePalette.warning)
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
            .financeScreenSurface()

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

struct DebtsTab: View {
    @Binding var snapshot: FinanceSnapshot
    let onSave: () -> Void
    @State private var showAdd = false

    private var ledger: FinanceLedger { FinanceLedger(snapshot: snapshot) }

    private func linkableCards(for liability: FinanceLiability) -> [FinanceCard] {
        snapshot.cards.filter { card in
            guard card.kind == .credit else { return false }
            let currency = card.currency
                ?? snapshot.accounts.first(where: { $0.id == card.linkedAccountID })?.currency
                ?? "EGP"
            let alreadyLinked = snapshot.liabilities.contains {
                $0.linkedCardID == card.id && $0.id != liability.id
            }
            return currency == liability.currency && !alreadyLinked
        }
    }

    private var creditCards: [FinanceCard] {
        snapshot.cards.filter { $0.kind == .credit }
    }

    private var standaloneLiabilities: [FinanceLiability] {
        snapshot.liabilities.filter { $0.linkedCardID == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                creditCardSection
                debtSummarySection
                debtListSection
            }
            .listStyle(.insetGrouped)
            .financeScreenSurface()
            .navigationTitle("Debts")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAdd) {
                LiabilityEntrySheet { item in
                    snapshot.liabilities.append(item)
                    onSave()
                }
            }
        }
    }

    private var creditCardSection: some View {
        Section("Credit cards · calculated balances") {
            if creditCards.isEmpty {
                Text("Add a credit card in Accounts to track purchases and repayments.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(creditCards) { card in
                CreditCardDebtRow(
                    card: card,
                    currency: currency(for: card),
                    outstanding: (try? ledger.creditCardOutstanding(for: card.id)) ?? 0
                )
            }
        }
    }

    private var debtSummarySection: some View {
        let groups = Dictionary(grouping: standaloneLiabilities, by: \.currency)
        return Section("Other recorded debt by currency") {
            ForEach(groups.keys.sorted(), id: \.self) { currency in
                let total = groups[currency, default: []].reduce(Decimal.zero) { partial, item in
                    partial + item.outstandingAmount
                }
                HStack {
                    Text(currency)
                    Spacer()
                    Text(total, format: .currency(code: currency))
                        .font(.headline).monospacedDigit()
                }
            }
            Text("If a standalone credit-card liability is the opening balance of a listed card, link it to that card to prevent double counting.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var debtListSection: some View {
        Section("Loans, instalments and standalone debts") {
            if standaloneLiabilities.isEmpty {
                ContentUnavailableView(
                    "No other debts recorded",
                    systemImage: "checkmark.circle",
                    description: Text("Add a loan, instalment or standalone debt.")
                )
            }
            ForEach(standaloneLiabilities) { item in
                LiabilityDebtRow(
                    item: item,
                    linkableCards: item.kind == .creditCard ? linkableCards(for: item) : [],
                    onLink: { card in
                        var updatedLedger = FinanceLedger(snapshot: snapshot)
                        do {
                            try updatedLedger.linkOpeningLiability(item.id, to: card.id)
                            snapshot = updatedLedger.snapshot
                            onSave()
                        } catch { }
                    }
                )
            }
            .onDelete { offsets in
                let items = standaloneLiabilities
                for index in offsets {
                    snapshot.liabilities.removeAll { $0.id == items[index].id }
                }
                onSave()
            }
            Button {
                showAdd = true
            } label: {
                Label("Add loan / debt", systemImage: "plus.circle.fill")
                    .frame(minHeight: 44)
            }
        }
    }

    private func currency(for card: FinanceCard) -> String {
        if let currency = card.currency { return currency }
        if let account = snapshot.accounts.first(where: { $0.id == card.linkedAccountID }) {
            return account.currency
        }
        return "EGP"
    }
}

struct AssetsZakatTab: View {
    @Binding var snapshot: FinanceSnapshot
    let onSave: () -> Void
    @Binding var preferences: FinancePreferences
    @State private var comparison: ZakatCalculationComparison?
    @State private var editingHolding: Holding?
    @State private var editorKind: HoldingKind = .cash
    @State private var showHoldingEditor = false
    @State private var assetError: String?
    @State private var showHawlCalendar = false

    var body: some View {
        NavigationStack {
            List {
                hawlCalendarSection
                assetsSection
                zakatCalculationSection
                valuationRatesSection
            }
            .onChange(of: preferences) { _, _ in
                if comparison != nil { calculate() }
            }
            .onChange(of: snapshot.holdings) { _, _ in
                if comparison != nil { calculate() }
            }
            .listStyle(.insetGrouped)
            .financeScreenSurface()
            .navigationTitle("Savings & Zakat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showHawlCalendar) {
                HawlCalendarView(holdings: snapshot.holdings)
            }
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
                        if editingHolding != nil {
                            Task { await HawlNotificationScheduler().cancel(holdingID: updated.id) }
                        }
                        onSave()
                        calculate()
                    } catch {
                        assetError = validationMessage(for: error)
                    }
                }
            }
        }
    }

    private func assetIcon(for kind: HoldingKind) -> String {
        switch kind {
        case .cash: return "banknote"
        case .gold: return "circle.lefthalf.filled"
        case .silver: return "circle"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }

    private func assetColor(for kind: HoldingKind) -> Color {
        switch kind {
        case .cash: return FinancePalette.royalBlue
        case .gold: return FinancePalette.gold
        case .silver: return .secondary
        case .investment: return FinancePalette.violet
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
            guard let currency = holding.currency?.uppercased(), let rate = preferences.exchangeRatesToEGP[currency], rate.isFinite, rate > 0 else { return nil }
            return holding.amount * rate
        case .gold:
            guard let price = preferences.goldPricesPerGramEGP[String(holding.carat ?? 24)], price.isFinite, price > 0 else { return nil }
            return (holding.grams ?? holding.amount) * price
        case .silver:
            guard let price = preferences.silverPricePerGramEGP, price.isFinite, price > 0 else { return nil }
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
        let month = (1...12).contains(hijri.hijriMonth) ? monthNames[hijri.hijriMonth] : "Month \(hijri.hijriMonth)"
        if status == .officiallyConfirmed && hijri.status == .officiallyConfirmed {
            return "Egyptian Hijri \(hijri.hijriDay) \(month) \(hijri.hijriYear) (Confirmed)"
        }
        return "Hijri estimate \(hijri.hijriDay) \(month) \(hijri.hijriYear) (not official Egyptian date)"
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
            Task { await HawlNotificationScheduler().cancel(holdingID: holding.id) }
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

    private func breakdownTitle(_ status: ZakatHoldingStatus) -> String {
        switch status {
        case .included: return "Included"
        case .waitingForHawl: return "Waiting for Hawl"
        case .excludedPersonalUse: return "Excluded"
        case .missingValuation: return "Missing valuation"
        case .invalid: return "Invalid asset"
        }
    }


    private func assetEntryButton(for kind: HoldingKind) -> some View {
        Button {
            editingHolding = nil
            editorKind = kind
            showHoldingEditor = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: addIcon(for: kind))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(assetColor(for: kind))
                    .frame(width: 40, height: 40)
                    .background(assetColor(for: kind).opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
                Text(addTitle(for: kind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Image(systemName: "plus.circle")
                    .font(.body.weight(.medium))
                    .foregroundStyle(FinancePalette.royalBlue)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(FinancePalette.whiteSurface,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 64)
        .accessibilityLabel(addTitle(for: kind))
        .accessibilityHint("Create a new \(kind.rawValue) asset")
        .accessibilityIdentifier("add-asset-\(kind.rawValue)")
    }

    private var assetsSection: some View {
        Section("Savings and Zakat assets") {
            if snapshot.holdings.isEmpty {
                Text("No assets recorded yet. Add cash, gold, silver or a manual investment below.")
                    .foregroundStyle(.secondary)
            }
            ForEach(snapshot.holdings) { holding in
                Button {
                    editingHolding = holding
                    editorKind = holding.kind
                    showHoldingEditor = true
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 10) {
                            Image(systemName: assetIcon(for: holding.kind))
                                .font(.headline)
                                .foregroundStyle(assetColor(for: holding.kind))
                                .frame(width: 34, height: 34)
                                .background(assetColor(for: holding.kind).opacity(0.10),
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .accessibilityHidden(true)
                            Text(label(holding)).font(.headline).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        Text("Acquired: \(holding.acquiredDate.formatted(date: .abbreviated, time: .omitted)) · Hawl starts: \(holding.hawlStartDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                        if let due = HawlCalculator.dueDateResult(startDate: holding.hawlStartDate) {
                            let days = cairoDayDifference(from: Date(), to: due.date)
                            HStack(spacing: 6) {
                                Text("Hawl due: " + due.date.formatted(date: .abbreviated, time: .omitted))
                                Text("· " + hijriLabel(for: due.date, status: due.status))
                                Text(days >= 0 ? "· \(days) days left" : "· Matured")
                            }
                            .font(.caption)
                            .foregroundStyle(due.status == .officiallyConfirmed ? Color.secondary : FinancePalette.warning)
                        }
                        if let value = estimatedValueEGP(for: holding) {
                            Text(value, format: .currency(code: "EGP"))
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        } else {
                            Text("Valuation needed")
                                .font(.caption).foregroundStyle(FinancePalette.warning)
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
            // Keep each action as a direct List row. This gives VoiceOver and
            // UI automation a distinct, full-width target for every asset type.
            assetEntryButton(for: .cash)
            assetEntryButton(for: .gold)
            assetEntryButton(for: .silver)
            assetEntryButton(for: .investment)
            if let assetError {
                Text(assetError).font(.footnote).foregroundStyle(FinancePalette.danger)
            }
        }
    }

    private var hawlCalendarSection: some View {
        Section("Hawl calendar") {
            Button {
                showHawlCalendar = true
            } label: {
                Label("View Hawl calendar and reminders", systemImage: "calendar.badge.clock")
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("View Hawl calendar and reminders")
            .accessibilityHint("Open Hawl dates and reminder settings")
            .accessibilityIdentifier("hawl-calendar-link")
        }
    }

    private var zakatCalculationSection: some View {
        Section("Combined Zakat calculation") {
            ZakatCalculationContent(
                preferences: $preferences,
                onSave: onSave,
                comparison: comparison,
                onCalculate: calculate,
                onSaveSelectedResult: saveSelectedResult,
                breakdownTitle: breakdownTitle
            )
        }
    }

    private var valuationRatesSection: some View {
        Section("Manual valuation rates") {
            ForEach(["SAR", "USD", "AED", "EUR", "GBP"], id: \.self) { code in
                HStack {
                    Text("1 \(code) = EGP")
                    TextField("Rate", value: Binding(
                        get: { preferences.exchangeRatesToEGP[code] ?? 0 },
                        set: { preferences.exchangeRatesToEGP[code] = $0; onSave() }
                    ),
                              format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
            }
            ForEach(["24", "22", "21", "18", "14"], id: \.self) { carat in
                HStack {
                    Text("Gold \(carat)K / gram")
                    TextField("EGP", value: Binding(
                        get: { preferences.goldPricesPerGramEGP[carat] ?? 0 },
                        set: { preferences.goldPricesPerGramEGP[carat] = $0; onSave() }
                    ),
                              format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
            }
            HStack {
                Text("Silver / gram (999)")
                TextField("EGP", value: Binding(
                    get: { preferences.silverPricePerGramEGP ?? 0 },
                    set: { preferences.silverPricePerGramEGP = $0; onSave() }
                ),
                          format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
            }
        }
    }

    private func calculate() {
        comparison = ZakatCalculator.calculateComparison(
            holdings: snapshot.holdings,
            ratesToEGP: preferences.exchangeRatesToEGP,
            goldPricesPerGramEGP: preferences.goldPricesPerGramEGP,
            silverPricePerGramEGP: preferences.silverPricePerGramEGP,
            nisabEGP: preferences.nisabEGP,
            asOf: Date(),
            includePersonalGold: preferences.includePersonalGold
        )
    }

    private func saveSelectedResult(_ selected: ZakatResult) {
        preferences.savedZakatCalculation = SavedZakatCalculation(
            result: selected,
            holdings: snapshot.holdings,
            preferences: preferences
        )
        onSave()
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
        let month = (1...12).contains(hijri.hijriMonth) ? monthNames[hijri.hijriMonth] : "Month \(hijri.hijriMonth)"
        if hijri.status == .officiallyConfirmed {
            return "Egyptian Hijri date: \(hijri.hijriDay) \(month) \(hijri.hijriYear) · Confirmed"
        }
        return "Hijri estimate: \(hijri.hijriDay) \(month) \(hijri.hijriYear) · Not an official Egyptian date"
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
            .financeScreenSurface()

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
                .foregroundStyle(transaction.direction == .income ? FinancePalette.income :
                                    transaction.direction == .expense ? FinancePalette.expense : FinancePalette.royalBlue)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title).font(.headline)
                Text([transaction.direction.rawValue.capitalized, transaction.category, accountName,
                      transaction.date.formatted(date: .abbreviated, time: .omitted)]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
                if transaction.reviewStatus == .needsReview {
                    Text("Needs review").font(.caption2).foregroundStyle(FinancePalette.warning)
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
            .financeScreenSurface()

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
    private enum EntryKind: String, CaseIterable {
        case account = "Account transaction"
        case cardPurchase = "Credit-card purchase"
        case cardRepayment = "Credit-card repayment"
    }

    let accounts: [FinanceAccount]
    let cards: [FinanceCard]
    let onSave: (FinanceTransaction) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var entryKind = EntryKind.account
    @State private var title = ""
    @State private var amount = ""
    @State private var direction = TransactionDirection.expense
    @State private var date = Date()
    @State private var accountID: UUID?
    @State private var destinationAccountID: UUID?
    @State private var cardID: UUID?
    @State private var category = "Shopping"

    private let categories = ["Food", "Transport", "Shopping", "Bills", "Housing", "Health", "Education", "Salary", "Other"]
    private var creditCards: [FinanceCard] { cards.filter { $0.kind == .credit } }
    private var selectedAccount: FinanceAccount? { accounts.first(where: { $0.id == accountID }) }
    private var selectedCard: FinanceCard? { creditCards.first(where: { $0.id == cardID }) }
    private var cardCurrency: String? {
        guard let selectedCard else { return nil }
        return selectedCard.currency
            ?? accounts.first(where: { $0.id == selectedCard.linkedAccountID })?.currency
            ?? "EGP"
    }
    private var eligiblePaymentCards: [FinanceCard] {
        guard let selectedAccount else { return [] }
        return creditCards.filter { candidate in
            let currency = candidate.currency
                ?? accounts.first(where: { $0.id == candidate.linkedAccountID })?.currency
                ?? "EGP"
            return currency == selectedAccount.currency
        }
    }

    init(accounts: [FinanceAccount], cards: [FinanceCard], onSave: @escaping (FinanceTransaction) -> Void) {
        self.accounts = accounts
        self.cards = cards
        self.onSave = onSave
        let firstAccount = accounts.first
        _accountID = State(initialValue: firstAccount?.id)
        _destinationAccountID = State(initialValue: accounts.first(where: {
            $0.id != firstAccount?.id && $0.currency == firstAccount?.currency
        })?.id)
        _cardID = State(initialValue: cards.first(where: { $0.kind == .credit })?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Entry type", selection: $entryKind) {
                    ForEach(EntryKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Description", text: $title)
                TextField("Amount", text: $amount).keyboardType(.decimalPad)

                if entryKind == .account {
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
                                               description: Text("Account transactions require an account."))
                    }
                } else if entryKind == .cardPurchase {
                    if creditCards.isEmpty {
                        ContentUnavailableView("No credit cards", systemImage: "creditcard",
                                               description: Text("Add a credit card in Accounts first."))
                    } else {
                        Picker("Credit card", selection: $cardID) {
                            ForEach(creditCards) { Text($0.name).tag(Optional($0.id)) }
                        }
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                        if let cardCurrency { LabeledContent("Currency", value: cardCurrency) }
                        Text("The purchase increases card debt. It does not reduce your bank balance.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } else {
                    if !accounts.isEmpty {
                        Picker("Pay from account", selection: $accountID) {
                            ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
                        }
                    }
                    if eligiblePaymentCards.isEmpty {
                        ContentUnavailableView("No matching credit card", systemImage: "creditcard",
                                               description: Text("Add a credit card in the same currency as the paying account."))
                    } else {
                        Picker("Credit card", selection: $cardID) {
                            ForEach(eligiblePaymentCards) { Text($0.name).tag(Optional($0.id)) }
                        }
                        Text("A repayment reduces both the bank balance and card debt. It is not an expense.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if let selectedAccount { LabeledContent("Currency", value: selectedAccount.currency) }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }
            .financeScreenSurface()

            .navigationTitle("Add transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Decimal(string: amount), value > 0 else { return }
                        let item: FinanceTransaction
                        switch entryKind {
                        case .account:
                            guard let accountID, let selectedAccount else { return }
                            if direction == .transfer && (destinationAccountID == nil || destinationAccountID == accountID) { return }
                            item = FinanceTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      amount: value, currency: selectedAccount.currency,
                                                      direction: direction, date: date, accountID: accountID,
                                                      destinationAccountID: direction == .transfer ? destinationAccountID : nil,
                                                      category: direction == .transfer ? "Transfer" : category)
                        case .cardPurchase:
                            guard let selectedCard, let cardCurrency else { return }
                            item = FinanceTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      amount: value, currency: cardCurrency, direction: .expense,
                                                      date: date,
                                                      category: "Card purchase · \(selectedCard.name) · \(category)",
                                                      cardID: selectedCard.id)
                        case .cardRepayment:
                            guard let accountID, let selectedAccount, let selectedCard,
                                  selectedAccount.currency == (selectedCard.currency
                                    ?? accounts.first(where: { $0.id == selectedCard.linkedAccountID })?.currency
                                    ?? "EGP") else { return }
                            item = FinanceTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                                      amount: value, currency: selectedAccount.currency,
                                                      direction: .transfer, date: date, accountID: accountID,
                                                      category: "Card repayment · \(selectedCard.name)",
                                                      destinationCardID: selectedCard.id)
                        }
                        onSave(item)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              !(Decimal(string: amount).map { $0 > 0 } ?? false) ||
                              (entryKind == .account && (accounts.isEmpty || accountID == nil ||
                                (direction == .transfer && (destinationAccountID == nil || destinationAccountID == accountID)))) ||
                              (entryKind == .cardPurchase && selectedCard == nil) ||
                              (entryKind == .cardRepayment && (selectedAccount == nil || !eligiblePaymentCards.contains(where: { $0.id == cardID }))))
                }
            }
            .onChange(of: entryKind) { _, newValue in
                if newValue == .cardRepayment && !eligiblePaymentCards.contains(where: { $0.id == cardID }) {
                    cardID = eligiblePaymentCards.first?.id
                } else if newValue == .cardPurchase && selectedCard == nil {
                    cardID = creditCards.first?.id
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
                if entryKind == .cardRepayment, !eligiblePaymentCards.contains(where: { $0.id == cardID }) {
                    cardID = eligiblePaymentCards.first?.id
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
            .financeScreenSurface()

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
            .financeScreenSurface()

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
            .financeScreenSurface()

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


private struct ZakatCalculationContent: View {
    @Binding var preferences: FinancePreferences
    let onSave: () -> Void
    let comparison: ZakatCalculationComparison?
    let onCalculate: () -> Void
    let onSaveSelectedResult: (ZakatResult) -> Void
    let breakdownTitle: (ZakatHoldingStatus) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            nisabInput
            personalGoldSetting
            Button("Calculate Zakat", action: onCalculate)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("zakat-calculate-button")
            if let comparison {
                methodComparison(comparison)
                if let selectedResult {
                    resultTotals(selectedResult)
                    categoryRows(selectedResult)
                    breakdownRows(selectedResult)
                    provisionalWarnings(selectedResult)
                    Button("Save selected result") {
                        onSaveSelectedResult(selectedResult)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("zakat-save-selected-result")
                }
            }
            savedCalculationSummary
            Text("These are two calculation conventions for comparison, not a religious ruling. Scholarly views can differ; confirm the method and Nisab basis with a trusted scholar.")
                .font(.footnote).foregroundStyle(.secondary)
            Text("Confirm all prices, rates and asset dates before relying on either result.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var selectedResult: ZakatResult? {
        comparison?.result(for: preferences.effectiveZakatMethod)
    }

    private func methodComparison(_ comparison: ZakatCalculationComparison) -> some View {
        HStack(alignment: .top, spacing: 10) {
            methodCard(.independentCategories, result: comparison.independentCategories)
            methodCard(.separateHawlCombinedNisab, result: comparison.separateHawlCombinedNisab)
        }
    }

    private func methodCard(_ method: ZakatCalculationMethod, result: ZakatResult) -> some View {
        let isSelected = preferences.effectiveZakatMethod == method
        return VStack(alignment: .leading, spacing: 8) {
            Text(method.title)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text(result.zakatDueEGP, format: .currency(code: "EGP"))
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(FinancePalette.royalBlue)
                .fixedSize(horizontal: false, vertical: true)
            Text(method.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(result.isProvisional ? "Provisional" : "Calculated")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(result.isProvisional ? FinancePalette.warning : FinancePalette.income)
            Button(isSelected ? "Selected" : "Use this method") {
                preferences.selectedZakatMethod = method
                onSave()
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .disabled(isSelected)
            .accessibilityIdentifier("zakat-method-\(method.rawValue)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(isSelected ? FinancePalette.paleBlue : FinancePalette.whiteSurface,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? FinancePalette.royalBlue : FinancePalette.separator, lineWidth: isSelected ? 1.5 : 0.5)
        }
    }

    @ViewBuilder
    private var savedCalculationSummary: some View {
        if let saved = preferences.savedZakatCalculation {
            VStack(alignment: .leading, spacing: 5) {
                Text("Saved calculation snapshot").font(.headline)
                Text(saved.method.title).font(.subheadline.weight(.semibold))
                Text(saved.zakatDueEGP, format: .currency(code: "EGP"))
                    .font(.title3.bold()).monospacedDigit()
                Text("Calculated \(saved.calculatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
                Text(saved.isProvisional ? "Saved as provisional" : "Saved calculation")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(saved.isProvisional ? FinancePalette.warning : FinancePalette.income)
                Text("This snapshot does not change when assets, rates or prices are edited. Save again to replace it.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .accessibilityIdentifier("zakat-saved-calculation")
        }
    }

    private func categoryRows(_ result: ZakatResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Eligible wealth by category").font(.headline)
            Text(result.method == .independentCategories
                 ? "Each category is compared with the full Nisab independently."
                 : "Category totals are shown for transparency; Nisab is tested against their combined matured total.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(result.categoryBreakdown) { item in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.label).font(.subheadline)
                        Spacer()
                        Text(item.maturedEligibleWealthEGP, format: .currency(code: "EGP"))
                            .font(.subheadline.monospacedDigit())
                    }
                    HStack {
                        Text(item.meetsNisab ? "Category reaches Nisab" : "Below individual Nisab")
                        Spacer()
                        Text(item.zakatDueEGP, format: .currency(code: "EGP"))
                    }
                    .font(.caption).foregroundStyle(item.meetsNisab ? FinancePalette.income : Color.secondary)
                }
            }
        }
    }

    private var nisabInput: some View {
        HStack {
            Text("Nisab (EGP)")
            Spacer()
            TextField("Nisab", value: Binding(
                get: { preferences.nisabEGP },
                set: { preferences.nisabEGP = $0; onSave() }
            ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private var personalGoldSetting: some View {
        Toggle("Include personal-use gold", isOn: Binding(
            get: { preferences.includePersonalGold },
            set: { preferences.includePersonalGold = $0; onSave() }
        ))
    }

    private func resultTotals(_ result: ZakatResult) -> some View {
        VStack(spacing: 8) {
            valueRow("Total valued assets", result.totalValuedWealthEGP)
            valueRow("Completed-Hawl wealth", result.maturedEligibleWealthEGP)
            valueRow("Excluded personal-use gold", result.excludedWealthEGP)
            valueRow("Estimated Zakat", result.zakatDueEGP)
        }
    }

    private func valueRow(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("EGP \(value, format: .number.precision(.fractionLength(2)))").bold()
        }
    }

    private func breakdownRows(_ result: ZakatResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Asset calculation breakdown").font(.headline)
            ForEach(result.breakdown) { item in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.label).font(.subheadline.weight(.semibold))
                        Spacer()
                        if let value = item.valueEGP {
                            Text(value, format: .currency(code: "EGP"))
                                .font(.subheadline.monospacedDigit())
                        } else {
                            Text("Not valued").font(.caption).foregroundStyle(FinancePalette.warning)
                        }
                    }
                    Text(breakdownTitle(item.status) + " · " + item.explanation)
                        .font(.caption)
                        .foregroundStyle(item.status == .included ? Color.secondary : FinancePalette.warning)
                }
            }
        }
    }

    @ViewBuilder
    private func provisionalWarnings(_ result: ZakatResult) -> some View {
        if result.isProvisional {
            ForEach(result.warnings, id: \.self) { warning in
                Text(warning).font(.footnote).foregroundStyle(FinancePalette.warning)
            }
        }
    }
}


private struct WalletSummaryContent: View {
    let summary: MoneySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net worth · accounts and debts").font(.subheadline).foregroundStyle(.secondary)
            Text(summary.netWorth, format: .currency(code: "EGP"))
                 .font(.largeTitle.bold()).monospacedDigit()
                .foregroundStyle(FinancePalette.royalBlue)
                .accessibilityLabel("Net worth \(summary.netWorth) Egyptian pounds")
            HStack(spacing: 18) {
                metric("Assets", summary.totalAssets, color: FinancePalette.royalBlue)
                metric("Debts", summary.totalLiabilities, color: FinancePalette.violet)
            }
            Text("This first summary excludes unvalued gold and silver holdings.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if summary.isProvisional {
                Label("Some currencies need exchange rates", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(FinancePalette.warning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(FinancePalette.paleBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .listRowBackground(Color.clear)
    }

    private func metric(_ title: String, _ value: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .currency(code: "EGP"))
                .font(.subheadline.bold()).foregroundStyle(color)
        }
    }
}

private struct WalletAccountsContent: View {
    let accounts: [FinanceAccount]
    let ledger: FinanceLedger

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if accounts.isEmpty {
                ContentUnavailableView("No accounts yet", systemImage: "building.columns",
                                       description: Text("Add a bank, cash or savings account from Accounts."))
            } else {
                ForEach(accounts) { account in
                    WalletAccountRow(account: account, balance: (try? ledger.balance(for: account.id)) ?? 0)
                }
            }
        }
    }
}

private struct WalletAccountRow: View {
    let account: FinanceAccount
    let balance: Decimal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon(for: account.kind))
                .font(.title3)
                .foregroundStyle(account.kind == .savings ? FinancePalette.violet : FinancePalette.royalBlue)
                .frame(width: 36, height: 36)
                .background(FinancePalette.whiteSurface.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(account.name).font(.headline)
                Text(account.institution ?? account.kind.rawValue.capitalized)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(balance, format: .currency(code: account.currency))
                .font(.subheadline.weight(.semibold)).monospacedDigit()
        }
        .padding(.vertical, 3)
    }

    private func icon(for kind: FinanceAccountKind) -> String {
        switch kind {
        case .bank: return "building.columns"
        case .cash: return "banknote"
        case .savings: return "safe"
        case .wallet: return "wallet.bifold"
        }
    }
}


private struct WalletRecentActivityContent: View {
    let transactions: [FinanceTransaction]
    let accountName: (UUID?) -> String?

    var body: some View {
        Group {
            if transactions.isEmpty {
                Text("Your confirmed income, expenses and transfers will appear here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(transactions.sorted { $0.date > $1.date }.prefix(5)) { transaction in
                    TransactionRow(transaction: transaction, accountName: accountName(transaction.accountID))
                }
            }
        }
    }
}

private struct WalletQuickOverviewContent: View {
    @Binding var snapshot: FinanceSnapshot

    private var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            countTile(
                title: "Cards",
                count: snapshot.cards.count,
                icon: "creditcard",
                color: FinancePalette.royalBlue
            )
            countTile(
                title: "Loans & debts",
                count: snapshot.liabilities.count,
                icon: "doc.text",
                color: FinancePalette.violet
            )
            countTile(
                title: "Savings & Zakat assets",
                count: snapshot.holdings.count,
                icon: "sparkles",
                color: FinancePalette.gold
            )
        }
        .padding(.vertical, 8)
    }

    private func countTile(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            Text("\(count)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .padding(12)
        .background(FinancePalette.whiteSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(title)")
        .accessibilityIdentifier("wallet-overview-\(icon)")
    }
}


private struct CreditCardDebtRow: View {
    let card: FinanceCard
    let currency: String
    let outstanding: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.name).font(.headline)
            HStack {
                Text("Outstanding")
                Spacer()
                Text(outstanding, format: .currency(code: currency))
                    .font(.subheadline.bold()).monospacedDigit()
                    .foregroundStyle(FinancePalette.violet)
                    .accessibilityIdentifier("debt-card-outstanding-\(card.name)")
            }
            if let due = card.paymentDueDate {
                Label("Due \(due.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .font(.caption).foregroundStyle(FinancePalette.warning)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LiabilityDebtRow: View {
    let item: FinanceLiability
    let linkableCards: [FinanceCard]
    let onLink: (FinanceCard) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.name).font(.headline)
            HStack {
                Text(item.kind.rawValue.capitalized)
                Spacer()
                Text(item.outstandingAmount, format: .currency(code: item.currency))
                    .font(.subheadline.bold()).monospacedDigit()
                    .foregroundStyle(FinancePalette.violet)
            }
            .font(.caption)
            if let due = item.dueDate {
                Label("Due \(due.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .font(.caption).foregroundStyle(FinancePalette.warning)
            }
            if item.kind == .creditCard && !linkableCards.isEmpty {
                Menu("Link to credit card") {
                    ForEach(linkableCards) { card in
                        Button(card.name) { onLink(card) }
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
