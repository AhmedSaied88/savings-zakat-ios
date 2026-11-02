import Foundation

enum ZakatCalculator {
    static func calculate(
        holdings: [Holding],
        ratesToEGP: [String: Double],
        goldPricesPerGramEGP: [String: Double],
        silverPricePerGramEGP: Double?,
        nisabEGP: Double,
        asOf: Date,
        includePersonalGold: Bool = false,
        method: ZakatCalculationMethod = .separateHawlCombinedNisab
    ) -> ZakatResult {
        var warnings: [String] = []
        var total = 0.0
        var eligible = 0.0
        var excluded = 0.0
        var nextDue: Date?
        var breakdown: [ZakatHoldingBreakdown] = []
        var eligibleByCategory = Dictionary(
            uniqueKeysWithValues: HoldingKind.allCases.map { ($0, 0.0) }
        )

        var cairo = Calendar(identifier: .gregorian)
        cairo.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        let calculationDay = cairo.startOfDay(for: asOf)

        for holding in holdings {
            let label = holdingLabel(holding)
            guard holding.amount.isFinite, holding.amount > 0 else {
                warnings.append("Invalid amount for \(label).")
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: nil,
                    status: .invalid, explanation: "Amount must be greater than zero."
                ))
                continue
            }

            let value: Double?
            var valuationFailureStatus: ZakatHoldingStatus = .missingValuation
            var valuationFailureExplanation = "A valid exchange rate or metal price is required."
            switch holding.kind {
            case .cash, .investment:
                let currency = (holding.currency ?? "EGP").uppercased()
                if let rate = ratesToEGP[currency], rate > 0, rate.isFinite {
                    value = holding.amount * rate
                } else {
                    value = nil
                    warnings.append("Missing valid EGP exchange rate for \(currency) (\(label)).")
                }
            case .gold:
                let grams = holding.grams ?? holding.amount
                let carat = holding.carat ?? 24
                if !grams.isFinite || grams <= 0 {
                    value = nil
                    valuationFailureStatus = .invalid
                    valuationFailureExplanation = "Gold weight must be greater than zero."
                    warnings.append("Invalid gold weight for \(label).")
                } else if ![14, 18, 21, 22, 24].contains(carat) {
                    value = nil
                    valuationFailureStatus = .invalid
                    valuationFailureExplanation = "Gold carat must be 14K, 18K, 21K, 22K or 24K."
                    warnings.append("Unsupported gold carat for \(label).")
                } else if let price = goldPricesPerGramEGP[String(carat)], price > 0, price.isFinite {
                    value = grams * price
                } else {
                    value = nil
                    warnings.append("Missing valid gold resale price for \(carat)K.")
                }
            case .silver:
                let grams = holding.grams ?? holding.amount
                let purity = holding.purity ?? 999
                if !grams.isFinite || grams <= 0 || !(800...999).contains(purity) {
                    value = nil
                    valuationFailureStatus = .invalid
                    valuationFailureExplanation = "Silver weight must be greater than zero and purity must be between 800‰ and 999‰."
                    warnings.append("Invalid silver weight or purity for \(label).")
                } else if let price = silverPricePerGramEGP, price > 0, price.isFinite {
                    value = grams * price * Double(purity) / 1000
                } else {
                    value = nil
                    warnings.append("Missing valid silver price per gram.")
                }
            }

            guard let value, value.isFinite, value >= 0 else {
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: nil,
                    status: valuationFailureStatus, explanation: valuationFailureExplanation
                ))
                continue
            }

            total += value
            let personalGoldExcluded = holding.kind == .gold &&
                holding.purpose == .personalUse && !includePersonalGold
            guard let hawl = HawlCalculator.dueDateResult(startDate: holding.hawlStartDate) else {
                warnings.append("Could not determine the Hawl date for \(label).")
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: value,
                    status: .waitingForHawl, explanation: "Hawl date could not be determined; excluded from eligible wealth."
                ))
                continue
            }

            if hawl.status == .estimated {
                warnings.append("Hawl date for \(label) is estimated because a complete official Egyptian month-start interval is not available.")
            }

            if personalGoldExcluded {
                excluded += value
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: value,
                    status: .excludedPersonalUse, explanation: "Personal-use gold is excluded by the current calculation setting."
                ))
                continue
            }

            let dueDay = cairo.startOfDay(for: hawl.date)
            if calculationDay >= dueDay {
                eligible += value
                eligibleByCategory[holding.kind, default: 0] += value
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: value,
                    status: .included, explanation: "Valued and this holding's Hawl is complete; included in eligible wealth."
                ))
            } else {
                if nextDue.map({ dueDay < cairo.startOfDay(for: $0) }) ?? true {
                    nextDue = dueDay
                }
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: value,
                    status: .waitingForHawl, explanation: "This holding's Hawl has not completed; it is not included yet."
                ))
            }
        }

        if nisabEGP <= 0 || !nisabEGP.isFinite {
            warnings.append("Enter a valid nisab value in EGP.")
        }
        let canCalculate = nisabEGP > 0 && nisabEGP.isFinite
        let categories = HoldingKind.allCases.map { category -> ZakatCategoryBreakdown in
            let categoryValue = eligibleByCategory[category, default: 0]
            let meetsNisab = canCalculate && categoryValue >= nisabEGP
            return ZakatCategoryBreakdown(
                category: category,
                label: categoryLabel(category),
                maturedEligibleWealthEGP: categoryValue,
                meetsNisab: meetsNisab,
                zakatDueEGP: meetsNisab ? categoryValue * 0.025 : 0
            )
        }

        let independentCategoriesZakat = categories.reduce(0) { $0 + $1.zakatDueEGP }
        let combinedZakat = canCalculate && eligible >= nisabEGP ? eligible * 0.025 : 0
        let zakat = method == .independentCategories ? independentCategoriesZakat : combinedZakat

        return ZakatResult(
            method: method,
            calculatedAt: asOf,
            totalValuedWealthEGP: total,
            maturedEligibleWealthEGP: eligible,
            excludedWealthEGP: excluded,
            nisabEGP: nisabEGP,
            zakatDueEGP: zakat,
            isProvisional: !warnings.isEmpty,
            warnings: warnings,
            nextDueDate: nextDue,
            breakdown: breakdown,
            categoryBreakdown: categories
        )
    }

    static func calculateComparison(
        holdings: [Holding],
        ratesToEGP: [String: Double],
        goldPricesPerGramEGP: [String: Double],
        silverPricePerGramEGP: Double?,
        nisabEGP: Double,
        asOf: Date,
        includePersonalGold: Bool = false
    ) -> ZakatCalculationComparison {
        let shared = (
            holdings: holdings,
            ratesToEGP: ratesToEGP,
            goldPricesPerGramEGP: goldPricesPerGramEGP,
            silverPricePerGramEGP: silverPricePerGramEGP,
            nisabEGP: nisabEGP,
            asOf: asOf,
            includePersonalGold: includePersonalGold
        )
        return ZakatCalculationComparison(
            independentCategories: calculate(
                holdings: shared.holdings,
                ratesToEGP: shared.ratesToEGP,
                goldPricesPerGramEGP: shared.goldPricesPerGramEGP,
                silverPricePerGramEGP: shared.silverPricePerGramEGP,
                nisabEGP: shared.nisabEGP,
                asOf: shared.asOf,
                includePersonalGold: shared.includePersonalGold,
                method: .independentCategories
            ),
            separateHawlCombinedNisab: calculate(
                holdings: shared.holdings,
                ratesToEGP: shared.ratesToEGP,
                goldPricesPerGramEGP: shared.goldPricesPerGramEGP,
                silverPricePerGramEGP: shared.silverPricePerGramEGP,
                nisabEGP: shared.nisabEGP,
                asOf: shared.asOf,
                includePersonalGold: shared.includePersonalGold,
                method: .separateHawlCombinedNisab
            )
        )
    }

    private static func holdingLabel(_ holding: Holding) -> String {
        switch holding.kind {
        case .cash: return "Cash (\(holding.currency ?? "EGP"))"
        case .gold: return "Gold \(holding.carat ?? 24)K"
        case .silver: return "Silver \(holding.purity ?? 999)‰"
        case .investment: return holding.name ?? "Investment"
        }
    }

    private static func categoryLabel(_ category: HoldingKind) -> String {
        switch category {
        case .cash: return "Cash & currencies"
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .investment: return "Investments"
        }
    }
}
