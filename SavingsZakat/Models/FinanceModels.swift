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

    init(id: UUID = UUID(), name: String, issuer: String? = nil, kind: FinanceCardKind, lastFour: String? = nil, linkedAccountID: UUID? = nil, creditLimit: Decimal? = nil, statementDate: Date? = nil, paymentDueDate: Date? = nil, minimumDue: Decimal? = nil) {
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
    var notes: String?

    init(id: UUID = UUID(), title: String, amount: Decimal, currency: String, direction: TransactionDirection, date: Date, accountID: UUID? = nil, destinationAccountID: UUID? = nil, source: TransactionSource = .manual, reviewStatus: TransactionReviewStatus = .confirmed, notes: String? = nil) {
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
        self.notes = notes
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

    init(id: UUID = UUID(), name: String, kind: FinanceLiabilityKind, outstandingAmount: Decimal, currency: String, dueDate: Date? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.outstandingAmount = outstandingAmount
        self.currency = currency.uppercased()
        self.dueDate = dueDate
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

    init(schemaVersion: Int = currentSchemaVersion, accounts: [FinanceAccount] = [], cards: [FinanceCard] = [], transactions: [FinanceTransaction] = [], liabilities: [FinanceLiability] = [], holdings: [Holding] = []) {
        self.schemaVersion = schemaVersion
        self.accounts = accounts
        self.cards = cards
        self.transactions = transactions
        self.liabilities = liabilities
        self.holdings = holdings
    }
}
