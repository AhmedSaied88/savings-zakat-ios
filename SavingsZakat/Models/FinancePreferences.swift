import Foundation

struct BankMessageRule: Identifiable, Codable, Equatable {
    var id: UUID
    var keyword: String
    var direction: TransactionDirection
    var category: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        keyword: String,
        direction: TransactionDirection,
        category: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        self.direction = direction
        self.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isEnabled = isEnabled
    }
}

struct FinancePreferences: Codable, Equatable {
    var exchangeRatesToEGP: [String: Double]
    var goldPricesPerGramEGP: [String: Double]
    var silverPricePerGramEGP: Double?
    var nisabEGP: Double
    var includePersonalGold: Bool
    var bankMessageRules: [BankMessageRule]

    init(
        exchangeRatesToEGP: [String: Double] = ["EGP": 1],
        goldPricesPerGramEGP: [String: Double] = [:],
        silverPricePerGramEGP: Double? = nil,
        nisabEGP: Double = 0,
        includePersonalGold: Bool = false,
        bankMessageRules: [BankMessageRule] = []
    ) {
        self.exchangeRatesToEGP = Dictionary(
            exchangeRatesToEGP.map { ($0.key.uppercased(), $0.value) },
            uniquingKeysWith: { _, latest in latest }
        )
        self.exchangeRatesToEGP["EGP"] = 1
        self.goldPricesPerGramEGP = goldPricesPerGramEGP
        self.silverPricePerGramEGP = silverPricePerGramEGP
        self.nisabEGP = nisabEGP
        self.includePersonalGold = includePersonalGold
        self.bankMessageRules = bankMessageRules
    }

    var enabledBankMessageRules: [BankMessageRule] {
        bankMessageRules.filter {
            $0.isEnabled &&
            $0.keyword.count >= 3 &&
            !$0.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
