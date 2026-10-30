import Foundation

enum FinanceAccountKind: String, Codable, CaseIterable {
    case bank
    case cash
    case savings
    case wallet
}

struct FinanceAccount: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var institution: String?
    var kind: FinanceAccountKind
    var currency: String
    var openingBalance: Decimal
    var isArchived: Bool

    init(id: UUID = UUID(), name: String, institution: String? = nil, kind: FinanceAccountKind, currency: String, openingBalance: Decimal = 0, isArchived: Bool = false) {
        self.id = id
        self.name = name
        self.institution = institution
        self.kind = kind
        self.currency = currency.uppercased()
        self.openingBalance = openingBalance
        self.isArchived = isArchived
    }
}

enum FinanceCardKind: String, Codable, CaseIterable {
    case debit
    case credit
    case prepaid
}

struct FinanceCard: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var issuer: String?
    var kind: FinanceCardKind
    /// Store only the final four digits. Never store a full PAN, CVV, PIN, or OTP.
    var lastFour: String?
    var linkedAccountID: UUID?
    var creditLimit: Decimal?
    var statementDate: Date?
    var paymentDueDate: Date?
    var minimumDue: Decimal?
    /// Currency used for card purchases and repayments. Optional for old snapshots.
    var currency: String?
    /// Starting amount owed before this app begins tracking card activity.
    var openingOutstandingBalance: Decimal?

    init(id: UUID = UUID(), name: String, issuer: String? = nil, kind: FinanceCardKind, lastFour: String? = nil, linkedAccountID: UUID? = nil, creditLimit: Decimal? = nil, statementDate: Date? = nil, paymentDueDate: Date? = nil, minimumDue: Decimal? = nil, currency: String? = nil, openingOutstandingBalance: Decimal? = nil) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.kind = kind
        let digits = lastFour.map { String($0.filter(\.isNumber).suffix(4)) }
        self.lastFour = digits?.isEmpty == false ? digits : nil
        self.linkedAccountID = linkedAccountID
        self.creditLimit = creditLimit
        self.statementDate = statementDate
        self.paymentDueDate = paymentDueDate
        self.minimumDue = minimumDue
        self.currency = currency?.uppercased()
        self.openingOutstandingBalance = openingOutstandingBalance
    }
}

enum TransactionDirection: String, Codable {
    case income
    case expense
    case transfer
}

enum TransactionSource: String, Codable {
    case manual
    case shortcut
    case importedText
}

enum TransactionReviewStatus: String, Codable {
    case needsReview
    case confirmed
}

struct FinanceTransaction: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Decimal
    var currency: String
    var direction: TransactionDirection
    var date: Date
    var accountID: UUID?
    var destinationAccountID: UUID?
    var source: TransactionSource
    var reviewStatus: TransactionReviewStatus
    var category: String?
    var notes: String?
    var importedMessageID: UUID?
    var recurringRuleID: UUID?
    var recurrenceOccurrenceDate: Date?
    /// Set for a purchase charged to a credit card; such a purchase does not debit a bank account.
    var cardID: UUID?
    /// Set for a bank-to-credit-card repayment; it is a transfer, not a second expense.
    var destinationCardID: UUID?

    init(id: UUID = UUID(), title: String, amount: Decimal, currency: String, direction: TransactionDirection, date: Date, accountID: UUID? = nil, destinationAccountID: UUID? = nil, source: TransactionSource = .manual, reviewStatus: TransactionReviewStatus = .confirmed, category: String? = nil, notes: String? = nil, importedMessageID: UUID? = nil, recurringRuleID: UUID? = nil, recurrenceOccurrenceDate: Date? = nil, cardID: UUID? = nil, destinationCardID: UUID? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.currency = currency.uppercased()
        self.direction = direction
        self.date = date
        self.accountID = accountID
        self.destinationAccountID = destinationAccountID
        self.source = source
        self.reviewStatus = reviewStatus
        self.category = category
        self.notes = notes
        self.importedMessageID = importedMessageID
        self.recurringRuleID = recurringRuleID
        self.recurrenceOccurrenceDate = recurrenceOccurrenceDate
        self.cardID = cardID
        self.destinationCardID = destinationCardID
    }
}

enum FinanceLiabilityKind: String, Codable, CaseIterable {
    case loan
    case installment
    case creditCard
    case otherDebt
}

struct FinanceLiability: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: FinanceLiabilityKind
    var outstandingAmount: Decimal
    var currency: String
    var dueDate: Date?
    /// Links a manually entered opening card balance to a credit card so it is not counted twice.
    var linkedCardID: UUID?

    init(id: UUID = UUID(), name: String, kind: FinanceLiabilityKind, outstandingAmount: Decimal, currency: String, dueDate: Date? = nil, linkedCardID: UUID? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.outstandingAmount = outstandingAmount
        self.currency = currency.uppercased()
        self.dueDate = dueDate
        self.linkedCardID = linkedCardID
    }
}


enum RecurringFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly

    func nextDate(after date: Date, interval: Int, calendar: Calendar) -> Date? {
        guard interval > 0 else { return nil }
        let component: Calendar.Component
        switch self {
        case .daily: component = .day
        case .weekly: component = .weekOfYear
        case .monthly: component = .month
        case .yearly: component = .year
        }
        return calendar.date(byAdding: component, value: interval, to: date)
    }
}

/// A user-defined income or expense template. It does not affect balances until an occurrence is generated.
struct RecurringTransaction: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var amount: Decimal
    var currency: String
    var direction: TransactionDirection
    var accountID: UUID
    var category: String?
    var frequency: RecurringFrequency
    var interval: Int
    var nextDueDate: Date
    var isEnabled: Bool

    init(id: UUID = UUID(), title: String, amount: Decimal, currency: String, direction: TransactionDirection,
         accountID: UUID, category: String? = nil, frequency: RecurringFrequency, interval: Int = 1,
         nextDueDate: Date, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.amount = amount
        self.currency = currency.uppercased()
        self.direction = direction
        self.accountID = accountID
        self.category = category
        self.frequency = frequency
        self.interval = interval
        self.nextDueDate = nextDueDate
        self.isEnabled = isEnabled
    }
}

struct FinanceSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var accounts: [FinanceAccount]
    var cards: [FinanceCard]
    var transactions: [FinanceTransaction]
    var liabilities: [FinanceLiability]
    var holdings: [Holding]
    var preferences: FinancePreferences?
    /// Optional for backward-compatible decoding of existing version-1 snapshots.
    var recurringTransactions: [RecurringTransaction]?

    init(schemaVersion: Int = currentSchemaVersion, accounts: [FinanceAccount] = [], cards: [FinanceCard] = [], transactions: [FinanceTransaction] = [], liabilities: [FinanceLiability] = [], holdings: [Holding] = [], preferences: FinancePreferences? = nil, recurringTransactions: [RecurringTransaction]? = nil) {
        self.schemaVersion = schemaVersion
        self.accounts = accounts
        self.cards = cards
        self.transactions = transactions
        self.liabilities = liabilities
        self.holdings = holdings
        self.preferences = preferences
        self.recurringTransactions = recurringTransactions
    }
}
