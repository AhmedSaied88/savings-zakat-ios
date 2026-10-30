import SwiftUI

struct CardEntrySheet: View {
    var accounts: [FinanceAccount]
    var onSave: (FinanceCard) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var issuer = ""
    @State private var kind = FinanceCardKind.debit
    @State private var lastFour = ""
    @State private var linkedAccountID: UUID?
    @State private var creditLimit = ""
    @State private var minimumDue = ""
    @State private var currency = "EGP"
    @State private var openingOutstandingBalance = ""
    @State private var statementDate = Date()
    @State private var paymentDueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Card label", text: $name)
                TextField("Bank / issuer", text: $issuer)
                Picker("Type", selection: $kind) {
                    ForEach(FinanceCardKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .accessibilityIdentifier("card-kind-picker")
                TextField("Last four digits only", text: Binding(
                    get: { lastFour },
                    set: { value in lastFour = String(value.filter(\.isNumber).suffix(4)) }
                ))
                .keyboardType(.numberPad)
                if !accounts.isEmpty {
                    Picker("Linked account", selection: $linkedAccountID) {
                        Text("Not linked").tag(UUID?.none)
                        ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                if kind == .credit {
                    Section("Credit card details") {
                        Picker("Currency", selection: $currency) {
                            ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                        }
                        .disabled(linkedAccountID != nil)
                        TextField("Opening outstanding balance (optional)", text: $openingOutstandingBalance).keyboardType(.decimalPad)
                        TextField("Credit limit (optional)", text: $creditLimit).keyboardType(.decimalPad)
                        TextField("Minimum payment (optional)", text: $minimumDue).keyboardType(.decimalPad)
                        DatePicker("Statement date", selection: $statementDate, displayedComponents: .date)
                        DatePicker("Payment due date", selection: $paymentDueDate, displayedComponents: .date)
                    }
                }
                Text("Never enter the full card number, CVV, PIN or OTP.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("New card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(FinanceCard(name: name.trimmingCharacters(in: .whitespacesAndNewlines), issuer: issuer.isEmpty ? nil : issuer, kind: kind, lastFour: lastFour, linkedAccountID: linkedAccountID, creditLimit: Decimal(string: creditLimit), statementDate: kind == .credit ? statementDate : nil, paymentDueDate: kind == .credit ? paymentDueDate : nil, minimumDue: Decimal(string: minimumDue), currency: currency, openingOutstandingBalance: kind == .credit ? (Decimal(string: openingOutstandingBalance) ?? 0) : nil))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (kind == .credit && (!(Decimal(string: openingOutstandingBalance).map { $0 >= 0 } ?? true) ||
                                !(Decimal(string: creditLimit).map { $0 >= 0 } ?? true) ||
                                !(Decimal(string: minimumDue).map { $0 >= 0 } ?? true))))
                }
            }
            .onChange(of: linkedAccountID) { _, newValue in
                if let account = accounts.first(where: { $0.id == newValue }) { currency = account.currency }
            }
        }
    }
}

struct LiabilityEntrySheet: View {
    var cards: [FinanceCard] = []
    var accounts: [FinanceAccount] = []
    var onSave: (FinanceLiability) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind = FinanceLiabilityKind.loan
    @State private var amount = ""
    @State private var currency = "EGP"
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var linkedCardID: UUID?

    private var linkedCard: FinanceCard? { cards.first(where: { $0.id == linkedCardID }) }
    private var linkedCardCurrency: String? {
        linkedCard?.currency ?? accounts.first(where: { $0.id == linkedCard?.linkedAccountID })?.currency ?? "EGP"
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Type", selection: $kind) {
                    ForEach(FinanceLiabilityKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                TextField("Outstanding amount", text: $amount).keyboardType(.decimalPad)
                if kind == .creditCard && !cards.filter({ $0.kind == .credit }).isEmpty {
                    Picker("Link to credit card", selection: $linkedCardID) {
                        Text("Standalone balance").tag(UUID?.none)
                        ForEach(cards.filter({ $0.kind == .credit })) { Text($0.name).tag(Optional($0.id)) }
                    }
                }
                if let linkedCardCurrency {
                    LabeledContent("Currency", value: linkedCardCurrency)
                } else {
                    Picker("Currency", selection: $currency) {
                        ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                    }
                }
                Toggle("Add due date", isOn: $hasDueDate)
                if hasDueDate { DatePicker("Due date", selection: $dueDate, displayedComponents: .date) }
            }
            .navigationTitle("New liability")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Decimal(string: amount), value > 0 else { return }
                        onSave(FinanceLiability(name: name.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, outstandingAmount: value, currency: linkedCardCurrency ?? currency, dueDate: hasDueDate ? dueDate : nil, linkedCardID: kind == .creditCard ? linkedCardID : nil))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(Decimal(string: amount).map { $0 > 0 } ?? false))
                }
            }
            .onChange(of: kind) { _, newValue in
                if newValue != .creditCard { linkedCardID = nil }
            }
        }
    }
}
