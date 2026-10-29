import Foundation

enum HoldingKind: String, Codable { case cash, gold, silver }
enum HoldingPurpose: String, Codable { case investment, personalUse }

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
}

struct ZakatResult {
    var totalValuedWealthEGP: Double
    var maturedEligibleWealthEGP: Double
    var nisabEGP: Double
    var zakatDueEGP: Double
    var isProvisional: Bool
    var warnings: [String]
    var nextDueDate: Date?
}