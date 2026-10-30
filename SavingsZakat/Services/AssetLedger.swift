import Foundation

struct AssetLedger {
    enum AssetError: Error, Equatable {
        case invalidAmount
        case invalidCurrency
        case invalidDates
        case invalidGoldCarat
        case invalidSilverPurity
        case missingInvestmentName
        case duplicateHolding(UUID)
        case holdingNotFound(UUID)
    }

    private(set) var holdings: [Holding]

    init(holdings: [Holding] = []) {
        self.holdings = holdings
    }

    mutating func add(_ holding: Holding, asOf: Date = Date()) throws {
        guard !holdings.contains(where: { $0.id == holding.id }) else {
            throw AssetError.duplicateHolding(holding.id)
        }
        try validate(holding, asOf: asOf)
        holdings.append(holding)
    }

    mutating func update(_ holding: Holding, asOf: Date = Date()) throws {
        guard let index = holdings.firstIndex(where: { $0.id == holding.id }) else {
            throw AssetError.holdingNotFound(holding.id)
        }
        try validate(holding, asOf: asOf)
        holdings[index] = holding
    }

    mutating func delete(id: UUID) throws {
        guard holdings.contains(where: { $0.id == id }) else {
            throw AssetError.holdingNotFound(id)
        }
        holdings.removeAll { $0.id == id }
    }

    private func validate(_ holding: Holding, asOf: Date) throws {
        guard holding.amount.isFinite, holding.amount > 0 else {
            throw AssetError.invalidAmount
        }

        switch holding.kind {
        case .cash, .investment:
            guard let currency = holding.currency?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !currency.isEmpty, currency.count == 3 else {
                throw AssetError.invalidCurrency
            }
            if holding.kind == .investment,
               holding.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                throw AssetError.missingInvestmentName
            }
        case .gold:
            let grams = holding.grams ?? holding.amount
            guard grams.isFinite, grams > 0 else { throw AssetError.invalidAmount }
            guard [14, 18, 21, 22, 24].contains(holding.carat ?? 24) else {
                throw AssetError.invalidGoldCarat
            }
        case .silver:
            let grams = holding.grams ?? holding.amount
            guard grams.isFinite, grams > 0 else { throw AssetError.invalidAmount }
            guard (800...999).contains(holding.purity ?? 999) else {
                throw AssetError.invalidSilverPurity
            }
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        let today = calendar.startOfDay(for: asOf)
        let acquired = calendar.startOfDay(for: holding.acquiredDate)
        let hawlStart = calendar.startOfDay(for: holding.hawlStartDate)
        guard acquired <= today, hawlStart >= acquired, hawlStart <= today else {
            throw AssetError.invalidDates
        }
    }
}
