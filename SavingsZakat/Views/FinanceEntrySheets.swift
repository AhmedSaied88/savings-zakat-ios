import SwiftUI

struct CardEntrySheet: View {
    var card: FinanceCard? = nil
    var accounts: [FinanceAccount]
    var currencyLocked: Bool = false
    var currentOutstandingBalance: Decimal? = nil
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
    @State private var currentOutstandingBalanceText = ""
    @State private var statementDate = Date()
    @State private var paymentDueDate = Date()
    @State private var hasPaymentDueDate = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Card label", text: $name)
                TextField("Bank / issuer", text: $issuer)
                Picker("Type", selection: $kind) {
                    ForEach(FinanceCardKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .accessibilityIdentifier("card-kind-picker")
                .disabled(card != nil)
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
                    .disabled(currencyLocked)
                }
                if kind == .credit {
                    Section("Credit card details") {
                        Picker("Currency", selection: $currency) {
                            ForEach(["EGP", "USD", "SAR", "AED", "EUR", "GBP"], id: \.self) { Text($0).tag($0) }
                        }
                        .disabled(linkedAccountID != nil || currencyLocked)
                        TextField("Current outstanding balance", text: $currentOutstandingBalanceText)
                            .keyboardType(.decimalPad)
                        TextField("Credit limit (optional)", text: $creditLimit).keyboardType(.decimalPad)
                        TextField("Minimum payment (optional)", text: $minimumDue).keyboardType(.decimalPad)
                        Toggle("Set payment due date", isOn: $hasPaymentDueDate)
                            .accessibilityIdentifier("card-payment-due-date-toggle")
                        if hasPaymentDueDate {
                            DatePicker("Payment due date", selection: $paymentDueDate, displayedComponents: .date)
                                .accessibilityIdentifier("card-payment-due-date-picker")
                        }
                    }
                }
                Text("Never enter the full card number, CVV, PIN or OTP.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle(card == nil ? "New card" : "Edit card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(FinanceCard(
                            id: card?.id ?? UUID(),
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            issuer: issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : issuer,
                            kind: kind,
                            lastFour: lastFour,
                            linkedAccountID: linkedAccountID,
                            creditLimit: Decimal(string: creditLimit),
                            statementDate: card?.statementDate,
                            paymentDueDate: kind == .credit && hasPaymentDueDate ? paymentDueDate : nil,
                            minimumDue: Decimal(string: minimumDue),
                            currency: currency,
                            openingOutstandingBalance: kind == .credit
                                ? (card == nil ? (Decimal(string: currentOutstandingBalanceText) ?? 0) : card?.openingOutstandingBalance)
                                : nil,
                            balanceAdjustment: kind == .credit && card != nil
                                ? ((Decimal(string: currentOutstandingBalanceText) ?? 0) -
                                   ((currentOutstandingBalance ?? 0) - (card?.balanceAdjustment ?? 0)))
                                : nil
                        ))
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (kind == .credit && (!(Decimal(string: currentOutstandingBalanceText).map { $0 >= 0 } ?? true) ||
                                !(Decimal(string: creditLimit).map { $0 >= 0 } ?? true) ||
                                !(Decimal(string: minimumDue).map { $0 >= 0 } ?? true))))
                }
            }
            .onAppear {
                guard let card else { return }
                name = card.name
                issuer = card.issuer ?? ""
                kind = card.kind
                lastFour = card.lastFour ?? ""
                linkedAccountID = card.linkedAccountID
                creditLimit = card.creditLimit.map(String.init(describing:)) ?? ""
                minimumDue = card.minimumDue.map(String.init(describing:)) ?? ""
                currency = card.currency ?? accounts.first(where: { $0.id == card.linkedAccountID })?.currency ?? "EGP"
                currentOutstandingBalanceText = currentOutstandingBalance.map(String.init(describing:))
                    ?? card.openingOutstandingBalance.map(String.init(describing:))
                    ?? "0"
                statementDate = card.statementDate ?? Date()
                if let due = card.paymentDueDate {
                    paymentDueDate = due
                    hasPaymentDueDate = true
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
        guard let linkedCard else { return nil }
        return linkedCard.currency
            ?? accounts.first(where: { $0.id == linkedCard.linkedAccountID })?.currency
            ?? "EGP"
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
                    Text("The linked liability becomes the card opening balance; it replaces any opening amount already stored on the card.")
                        .font(.footnote).foregroundStyle(.secondary)
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
