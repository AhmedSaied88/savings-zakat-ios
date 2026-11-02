import Foundation

enum HoldingKind: String, Codable, CaseIterable {
    case cash
    case gold
    case silver
    case investment
}

enum HoldingPurpose: String, Codable, CaseIterable {
    case investment
    case personalUse
}

struct Holding: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: HoldingKind
    var amount: Double
    var currency: String?
    var grams: Double?
    var carat: Int?
    var acquiredDate: Date
    var hawlStartDate: Date
    var purpose: HoldingPurpose
    var name: String? = nil
    var purity: Int? = nil
}

enum ZakatHoldingStatus: String, Codable, Equatable {
    case included
    case waitingForHawl
    case excludedPersonalUse
    case missingValuation
    case invalid
}

struct ZakatHoldingBreakdown: Identifiable, Codable, Equatable {
    var holdingID: UUID
    var label: String
    var valueEGP: Double?
    var status: ZakatHoldingStatus
    var explanation: String

    var id: UUID { holdingID }
}

struct ZakatCategoryBreakdown: Identifiable, Codable, Equatable {
    var category: HoldingKind
    var label: String
    var maturedEligibleWealthEGP: Double
    var meetsNisab: Bool
    var zakatDueEGP: Double

    var id: String { category.rawValue }
}

struct ZakatResult {
    var method: ZakatCalculationMethod
    var calculatedAt: Date
    var totalValuedWealthEGP: Double
    var maturedEligibleWealthEGP: Double
    var excludedWealthEGP: Double
    var nisabEGP: Double
    var zakatDueEGP: Double
    var isProvisional: Bool
    var warnings: [String]
    var nextDueDate: Date?
    var breakdown: [ZakatHoldingBreakdown]
    var categoryBreakdown: [ZakatCategoryBreakdown]
}

struct ZakatCalculationComparison {
    var independentCategories: ZakatResult
    var separateHawlCombinedNisab: ZakatResult

    func result(for method: ZakatCalculationMethod) -> ZakatResult {
        switch method {
        case .independentCategories: return independentCategories
        case .separateHawlCombinedNisab: return separateHawlCombinedNisab
        }
    }
}

/// An immutable result snapshot. Later price, rate or asset edits do not change it.
struct SavedZakatCalculation: Codable, Equatable {
    var method: ZakatCalculationMethod
    var calculatedAt: Date
    var totalValuedWealthEGP: Double
    var maturedEligibleWealthEGP: Double
    var excludedWealthEGP: Double
    var nisabEGP: Double
    var zakatDueEGP: Double
    var isProvisional: Bool
    var warnings: [String]
    var holdingBreakdown: [ZakatHoldingBreakdown]
    var categoryBreakdown: [ZakatCategoryBreakdown]
    var holdings: [Holding]
    var exchangeRatesToEGP: [String: Double]
    var goldPricesPerGramEGP: [String: Double]
    var silverPricePerGramEGP: Double?
    var includePersonalGold: Bool

    init(result: ZakatResult, holdings: [Holding], preferences: FinancePreferences) {
        method = result.method
        calculatedAt = result.calculatedAt
        totalValuedWealthEGP = result.totalValuedWealthEGP
        maturedEligibleWealthEGP = result.maturedEligibleWealthEGP
        excludedWealthEGP = result.excludedWealthEGP
        nisabEGP = result.nisabEGP
        zakatDueEGP = result.zakatDueEGP
        isProvisional = result.isProvisional
        warnings = result.warnings
        holdingBreakdown = result.breakdown
        categoryBreakdown = result.categoryBreakdown
        self.holdings = holdings
        exchangeRatesToEGP = preferences.exchangeRatesToEGP
        goldPricesPerGramEGP = preferences.goldPricesPerGramEGP
        silverPricePerGramEGP = preferences.silverPricePerGramEGP
        includePersonalGold = preferences.includePersonalGold
    }
}
