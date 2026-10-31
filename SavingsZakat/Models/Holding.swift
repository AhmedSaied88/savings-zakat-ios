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

enum ZakatHoldingStatus: String, Equatable {
    case included
    case waitingForHawl
    case excludedPersonalUse
    case missingValuation
    case invalid
}

struct ZakatHoldingBreakdown: Identifiable, Equatable {
    var holdingID: UUID
    var label: String
    var valueEGP: Double?
    var status: ZakatHoldingStatus
    var explanation: String

    var id: UUID { holdingID }
}

struct ZakatResult {
    var totalValuedWealthEGP: Double
    var maturedEligibleWealthEGP: Double
    var excludedWealthEGP: Double
    var nisabEGP: Double
    var zakatDueEGP: Double
    var isProvisional: Bool
    var warnings: [String]
    var nextDueDate: Date?
    var breakdown: [ZakatHoldingBreakdown]
}
