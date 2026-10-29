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
        var nextDue: Date?

        for holding in holdings {
            let value: Double?
            switch holding.kind {
            case .cash:
                let currency = holding.currency ?? "EGP"
                if let rate = ratesToEGP[currency], rate > 0, rate.isFinite { value = holding.amount * rate }
                else { value = nil; warnings.append("Missing valid EGP exchange rate for \(currency).") }
            case .gold:
                guard holding.purpose != .personalUse || includePersonalGold else { continue }
                let carat = holding.carat ?? 24
                if let price = goldPricesPerGramEGP[String(carat)], price > 0, price.isFinite { value = (holding.grams ?? holding.amount) * price }
                else { value = nil; warnings.append("Missing valid gold resale price for \(carat)K.") }
            case .silver:
                if let price = silverPricePerGramEGP, price > 0, price.isFinite { value = (holding.grams ?? holding.amount) * price }
                else { value = nil; warnings.append("Missing valid silver price per gram.") }
            }

            guard let value, value.isFinite, value >= 0 else { continue }
            total += value
            let completed = HawlCalculator.hasCompletedHawl(startDate: holding.hawlStartDate, asOf: asOf)
            if completed { eligible += value }
            else if let due = HawlCalculator.dueDate(startDate: holding.hawlStartDate), due > asOf, (nextDue.map { due < $0 } ?? true) { nextDue = due }
        }

        if nisabEGP <= 0 || !nisabEGP.isFinite { warnings.append("Enter a valid nisab value in EGP.") }
        let canCalculate = nisabEGP > 0 && nisabEGP.isFinite
        let zakat = canCalculate && eligible >= nisabEGP ? eligible * 0.025 : 0
        return ZakatResult(totalValuedWealthEGP: total, maturedEligibleWealthEGP: eligible, nisabEGP: nisabEGP, zakatDueEGP: zakat, isProvisional: !warnings.isEmpty, warnings: warnings, nextDueDate: nextDue)
    }
}