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

enum ZakatCalculationMethod: String, Codable, CaseIterable, Identifiable {
    case independentCategories
    case separateHawlCombinedNisab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .independentCategories: return "Independent categories"
        case .separateHawlCombinedNisab: return "Separate Hawl · combined Nisab"
        }
    }

    var explanation: String {
        switch self {
        case .independentCategories:
            return "Each category is tested against Nisab separately. Only matured holdings within that category are counted."
        case .separateHawlCombinedNisab:
            return "Each holding keeps its own Hawl. All matured eligible categories are combined to test Nisab."
        }
    }
}

struct FinancePreferences: Codable, Equatable {
    var exchangeRatesToEGP: [String: Double]
    var goldPricesPerGramEGP: [String: Double]
    var silverPricePerGramEGP: Double?
    var nisabEGP: Double
    var includePersonalGold: Bool
    var bankMessageRules: [BankMessageRule]
    // Optional fields preserve decoding of earlier version-1 finance snapshots.
    var selectedZakatMethod: ZakatCalculationMethod?
    var savedZakatCalculation: SavedZakatCalculation?

    init(
        exchangeRatesToEGP: [String: Double] = ["EGP": 1],
        goldPricesPerGramEGP: [String: Double] = [:],
        silverPricePerGramEGP: Double? = nil,
        nisabEGP: Double = 0,
        includePersonalGold: Bool = false,
        bankMessageRules: [BankMessageRule] = [],
        selectedZakatMethod: ZakatCalculationMethod = .separateHawlCombinedNisab,
        savedZakatCalculation: SavedZakatCalculation? = nil
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
        self.selectedZakatMethod = selectedZakatMethod
        self.savedZakatCalculation = savedZakatCalculation
    }

    var effectiveZakatMethod: ZakatCalculationMethod {
        selectedZakatMethod ?? .separateHawlCombinedNisab
    }

    var enabledBankMessageRules: [BankMessageRule] {
        bankMessageRules.filter {
            $0.isEnabled &&
            $0.keyword.count >= 3 &&
            !$0.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
