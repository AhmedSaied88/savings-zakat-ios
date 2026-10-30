import SwiftUI

struct SettingsHomeView: View {
    @Binding var snapshot: FinanceSnapshot
    @Binding var preferences: FinancePreferences
    let onSave: () -> Void
    let onRestore: (FinanceSnapshot) -> Bool

    var body: some View {
        NavigationStack {
            List {
                Section("Finance settings") {
                    NavigationLink {
                        FinancePreferencesView(
                            preferences: $preferences,
                            holdings: snapshot.holdings,
                            onSave: onSave
                        )
                    } label: {
                        Label("Valuation, parser & calendar", systemImage: "slider.horizontal.3")
                    }
                }
                Section("Data protection") {
                    NavigationLink {
                        BackupSettingsView(snapshot: $snapshot, onRestore: onRestore)
                    } label: {
                        Label("Backup & Restore", systemImage: "lock.doc")
                    }
                }
                Section("Privacy") {
                    Label("Financial records are stored locally on this iPhone.", systemImage: "iphone")
                    Label("Bank messages are received through user-configured Shortcuts, not inbox scanning.", systemImage: "message")
                    Label("Imported messages are redacted and require review before posting.", systemImage: "hand.raised")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct FinancePreferencesView: View {
    @Binding var preferences: FinancePreferences
    let holdings: [Holding]
    let onSave: () -> Void

    @State private var editingRule: BankMessageRule?
    @State private var showRuleEditor = false
    @State private var ruleError: String?

    var body: some View {
        Form {
            Section("Exchange rates to EGP") {
                ForEach(["SAR", "USD", "AED", "EUR", "GBP"], id: \.self) { currency in
                    HStack {
                        Text("1 \(currency)")
                        Spacer()
                        TextField("EGP rate", value: Binding(
                            get: { preferences.exchangeRatesToEGP[currency] ?? 0 },
                            set: { preferences.exchangeRatesToEGP[currency] = $0; onSave() }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                }
                Text("EGP is fixed at 1.00. Missing or invalid rates keep Zakat provisional.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("Metal prices") {
                ForEach(["24", "22", "21", "18", "14"], id: \.self) { carat in
                    HStack {
                        Text("Gold \(carat)K / gram")
                        Spacer()
                        TextField("EGP", value: Binding(
                            get: { preferences.goldPricesPerGramEGP[carat] ?? 0 },
                            set: { preferences.goldPricesPerGramEGP[carat] = $0; onSave() }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    }
                }
                HStack {
                    Text("Silver 999 / gram")
                    Spacer()
                    TextField("EGP", value: Binding(
                        get: { preferences.silverPricePerGramEGP ?? 0 },
                        set: { preferences.silverPricePerGramEGP = $0; onSave() }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                }
            }

            Section("Zakat assumptions") {
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
                Toggle("Include personal-use gold", isOn: Binding(
                    get: { preferences.includePersonalGold },
                    set: { preferences.includePersonalGold = $0; onSave() }
                ))
                Text("The app shows its assumptions and a per-asset calculation breakdown. This setting is a configurable method, not a universal religious ruling.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Section("Bank message parser rules") {
                if preferences.bankMessageRules.isEmpty {
                    Text("No custom rules. Built-in English and Arabic patterns remain active.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(preferences.bankMessageRules) { rule in
                    Button {
                        editingRule = rule
                        showRuleEditor = true
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(rule.keyword).font(.headline).foregroundStyle(.primary)
                                Spacer()
                                Text(rule.direction.rawValue.capitalized)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Text(rule.category + (rule.isEnabled ? "" : " · Disabled"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            preferences.bankMessageRules.removeAll { $0.id == rule.id }
                            onSave()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                Button {
                    editingRule = nil
                    showRuleEditor = true
                } label: {
                    Label("Add custom keyword rule", systemImage: "plus.circle")
                        .frame(minHeight: 44)
                }
                Text("A custom rule matches one keyword in a bank message. Custom matches are medium confidence and still require your review. If multiple custom rules match, the message stays unparsed rather than guessing.")
                    .font(.footnote).foregroundStyle(.secondary)
                if let ruleError {
                    Text(ruleError).font(.footnote).foregroundStyle(.red)
                }
            }

            Section("Egyptian calendar data") {
                LabeledContent("Bundled data version", value: EgyptianCalendarRepository.dataVersion)
                LabeledContent("Official month starts", value: "\(EgyptianCalendarRepository.officialMonthStarts.count)")
                if let first = EgyptianCalendarRepository.officialMonthStarts.first,
                   let last = EgyptianCalendarRepository.officialMonthStarts.last {
                    LabeledContent("Seed coverage", value: "\(first.gregorianStart.formatted(date: .abbreviated, time: .omitted)) – \(last.gregorianStart.formatted(date: .abbreviated, time: .omitted))")
                }
                Text("Dates outside fully bounded Dar Al-Ifta announcement intervals use an explicitly estimated Islamic-civil fallback, not an official Egyptian date.")
                    .font(.footnote).foregroundStyle(.secondary)
                NavigationLink {
                    HawlCalendarView(holdings: holdings)
                } label: {
                    Label("Hawl calendar & reminders", systemImage: "calendar.badge.clock")
                }
            }

            Section("Privacy") {
                Text("The app stores finance data on this device. It does not connect to bank APIs or scan the Messages inbox. Shortcuts passes selected message text to the app; authentication secrets are redacted before the import queue is saved.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Finance preferences")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRuleEditor) {
            BankMessageRuleEditor(rule: editingRule) { updated in
                if let index = preferences.bankMessageRules.firstIndex(where: { $0.id == updated.id }) {
                    preferences.bankMessageRules[index] = updated
                } else {
                    preferences.bankMessageRules.append(updated)
                }
                preferences.bankMessageRules.sort { $0.keyword.localizedCaseInsensitiveCompare($1.keyword) == .orderedAscending }
                onSave()
                ruleError = nil
            }
        }
    }
}

private struct BankMessageRuleEditor: View {
    let rule: BankMessageRule?
    let onSave: (BankMessageRule) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var keyword: String
    @State private var category: String
    @State private var direction: TransactionDirection
    @State private var isEnabled: Bool
    @State private var errorMessage: String?

    init(rule: BankMessageRule?, onSave: @escaping (BankMessageRule) -> Void) {
        self.rule = rule
        self.onSave = onSave
        _keyword = State(initialValue: rule?.keyword ?? "")
        _category = State(initialValue: rule?.category ?? "")
        _direction = State(initialValue: rule?.direction ?? .expense)
        _isEnabled = State(initialValue: rule?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Keyword or phrase", text: $keyword)
                TextField("Transaction category", text: $category)
                Picker("Direction", selection: $direction) {
                    Text("Income").tag(TransactionDirection.income)
                    Text("Expense").tag(TransactionDirection.expense)
                    Text("Transfer").tag(TransactionDirection.transfer)
                }
                Toggle("Enabled", isOn: $isEnabled)
                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle(rule == nil ? "Add parser rule" : "Edit parser rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard cleanKeyword.count >= 3, !cleanCategory.isEmpty else {
                            errorMessage = "Enter a keyword of at least 3 characters and a category."
                            return
                        }
                        onSave(BankMessageRule(
                            id: rule?.id ?? UUID(),
                            keyword: cleanKeyword,
                            direction: direction,
                            category: cleanCategory,
                            isEnabled: isEnabled
                        ))
                        dismiss()
                    }
                    .disabled(keyword.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 ||
                              category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
