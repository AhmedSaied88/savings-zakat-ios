import Foundation

struct MoneySummary: Equatable {
    var currency: String
    var totalAssets: Decimal
    var totalLiabilities: Decimal
    var netWorth: Decimal
    var isProvisional: Bool
    var warnings: [String]
}

struct FinanceLedger {
    enum LedgerError: Error, Equatable {
        case invalidAmount
        case accountNotFound(UUID)
        case duplicateTransaction(UUID)
        case transactionNeedsReview
        case invalidTransactionAccounts
        case currencyMismatch
        case accountHasActivity(UUID)
        case duplicateLiability(UUID)
        case invalidLiabilityAmount
    }

    private(set) var snapshot: FinanceSnapshot

    init(snapshot: FinanceSnapshot = FinanceSnapshot()) {
        self.snapshot = snapshot
    }

    func balance(for accountID: UUID) throws -> Decimal {
        guard let account = snapshot.accounts.first(where: { $0.id == accountID }) else {
            throw LedgerError.accountNotFound(accountID)
        }

        return snapshot.transactions
            .filter { $0.reviewStatus == .confirmed }
            .reduce(account.openingBalance) { balance, transaction in
                switch transaction.direction {
                case .income where transaction.accountID == accountID:
                    return balance + transaction.amount
                case .expense where transaction.accountID == accountID:
                    return balance - transaction.amount
                case .transfer:
                    if transaction.accountID == accountID {
                        return balance - transaction.amount
                    }
                    if transaction.destinationAccountID == accountID {
                        return balance + transaction.amount
                    }
                    return balance
                default:
                    return balance
                }
            }
    }

    mutating func post(_ transaction: FinanceTransaction) throws {
        guard transaction.amount > 0 else { throw LedgerError.invalidAmount }
        guard transaction.reviewStatus == .confirmed else { throw LedgerError.transactionNeedsReview }
        guard !snapshot.transactions.contains(where: { $0.id == transaction.id }) else {
            throw LedgerError.duplicateTransaction(transaction.id)
        }

        guard let sourceID = transaction.accountID,
              let source = snapshot.accounts.first(where: { $0.id == sourceID }) else {
            throw LedgerError.invalidTransactionAccounts
        }
        guard source.currency == transaction.currency else { throw LedgerError.currencyMismatch }

        switch transaction.direction {
        case .income, .expense:
            guard transaction.destinationAccountID == nil else {
                throw LedgerError.invalidTransactionAccounts
            }
        case .transfer:
            guard let destinationID = transaction.destinationAccountID,
                  destinationID != sourceID,
                  let destination = snapshot.accounts.first(where: { $0.id == destinationID }) else {
                throw LedgerError.invalidTransactionAccounts
            }
            guard destination.currency == transaction.currency else { throw LedgerError.currencyMismatch }
        }

        snapshot.transactions.append(transaction)
    }

    mutating func transfer(amount: Decimal, from sourceID: UUID, to destinationID: UUID, date: Date, title: String = "Transfer") throws {
        guard amount > 0 else { throw LedgerError.invalidAmount }
        guard sourceID != destinationID,
              let source = snapshot.accounts.first(where: { $0.id == sourceID }),
              let destination = snapshot.accounts.first(where: { $0.id == destinationID }) else {
            throw LedgerError.invalidTransactionAccounts
        }
        guard source.currency == destination.currency else { throw LedgerError.currencyMismatch }

        let transaction = FinanceTransaction(
            title: title,
            amount: amount,
            currency: source.currency,
            direction: .transfer,
            date: date,
            accountID: sourceID,
            destinationAccountID: destinationID
        )
        try post(transaction)
    }

    mutating func addLiability(_ liability: FinanceLiability) throws {
        guard liability.outstandingAmount > 0 else { throw LedgerError.invalidLiabilityAmount }
        guard !snapshot.liabilities.contains(where: { $0.id == liability.id }) else {
            throw LedgerError.duplicateLiability(liability.id)
        }
        snapshot.liabilities.append(liability)
    }

    mutating func removeAccount(id: UUID) throws {
        guard snapshot.accounts.contains(where: { $0.id == id }) else {
            throw LedgerError.accountNotFound(id)
        }
        let hasTransactions = snapshot.transactions.contains {
            $0.accountID == id || $0.destinationAccountID == id
        }
        let hasCards = snapshot.cards.contains { $0.linkedAccountID == id }
        guard !hasTransactions && !hasCards else { throw LedgerError.accountHasActivity(id) }
        snapshot.accounts.removeAll { $0.id == id }
    }

    func netWorth(in currency: String, rates: [String: Decimal]) -> MoneySummary {
        let target = currency.uppercased()
        var warnings: [String] = []
        var provisional = false

        func converted(_ amount: Decimal, from sourceCurrency: String, label: String) -> Decimal {
            let source = sourceCurrency.uppercased()
            if source == target { return amount }
            guard let rate = rates[source], rate > 0 else {
                provisional = true
                warnings.append("Missing (source) to (target) exchange rate for (label).")
                return 0
            }
            return amount * rate
        }

        let assets = snapshot.accounts.reduce(Decimal.zero) { total, account in
            let value = (try? balance(for: account.id)) ?? 0
            return total + converted(value, from: account.currency, label: account.name)
        }
        let liabilities = snapshot.liabilities.reduce(Decimal.zero) { total, liability in
            total + converted(liability.outstandingAmount, from: liability.currency, label: liability.name)
        }

        return MoneySummary(
            currency: target,
            totalAssets: assets,
            totalLiabilities: liabilities,
            netWorth: assets - liabilities,
            isProvisional: provisional,
            warnings: warnings
        )
    }
}
