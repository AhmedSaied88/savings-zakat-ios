import Foundation

enum ZakatCalculator {
    static func calculate(
        holdings: [Holding],
        ratesToEGP: [String: Double],
        goldPricesPerGramEGP: [String: Double],
        silverPricePerGramEGP: Double?,
        nisabEGP: Double,
        asOf: Date,
        includePersonalGold: Bool = false
    ) -> ZakatResult {
        var warnings: [String] = []
        var total = 0.0
        var eligible = 0.0
        var excluded = 0.0
        var nextDue: Date?
        var breakdown: [ZakatHoldingBreakdown] = []

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
                    warnings.append("Invalid gold weight for \(label).")
                } else if ![14, 18, 21, 22, 24].contains(carat) {
                    value = nil
                    warnings.append("Unsupported gold carat for \\(label).")
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
                    status: .missingValuation, explanation: "A valid exchange rate or metal price is required."
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
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: value,
                    status: .included, explanation: "Valued and Hawl completed; included in combined eligible wealth."
                ))
            } else {
                if nextDue.map({ dueDay < cairo.startOfDay(for: $0) }) ?? true {
                    nextDue = dueDay
                }
                breakdown.append(ZakatHoldingBreakdown(
                    holdingID: holding.id, label: label, valueEGP: value,
                    status: .waitingForHawl, explanation: "Hawl has not completed; not included yet."
                ))
            }
        }

        if nisabEGP <= 0 || !nisabEGP.isFinite {
            warnings.append("Enter a valid nisab value in EGP.")
        }
        let canCalculate = nisabEGP > 0 && nisabEGP.isFinite
        let zakat = canCalculate && eligible >= nisabEGP ? eligible * 0.025 : 0
        return ZakatResult(
            totalValuedWealthEGP: total,
            maturedEligibleWealthEGP: eligible,
            excludedWealthEGP: excluded,
            nisabEGP: nisabEGP,
            zakatDueEGP: zakat,
            isProvisional: !warnings.isEmpty,
            warnings: warnings,
            nextDueDate: nextDue,
            breakdown: breakdown
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
}
