import Foundation
import SunCalc

struct EgyptianAstronomicalEstimate {
    let hijriYear: Int
    let hijriMonth: Int
    let hijriDay: Int
    let monthStart: Date
    let calculationNote: String
}

/// Cairo-reference implementation of the visibility conditions described by
/// Dar Al-Ifta in fatwa 2345 (10 December 2011). It is an estimate only:
/// it does not reproduce the national observation committees or an official
/// sighting announcement.
struct EgyptianAstronomicalEstimator {
    static let cairoLatitude = 30.0444
    static let cairoLongitude = 31.2357

    private let latitude = cairoLatitude
    private let longitude = cairoLongitude
    private let conjunctionSearchDays = 40
    private let conjunctionScanHours = 6
    private let visibilityEveningSearch = 0...2
    private let minimumElongationDegrees = 8.0
    private let minimumMoonsetLag: TimeInterval = 10 * 60

    func estimate(
        containing date: Date,
        timeZone: TimeZone,
        officialMonthStarts: [EgyptianHijriMonthStart]
    ) -> EgyptianAstronomicalEstimate? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let target = gregorian.startOfDay(for: date)

        let conjunctions = recentConjunctions(endingAt: target)
        for conjunction in conjunctions.reversed() {
            guard let monthStart = firstVisibleMonthStart(
                after: conjunction,
                timeZone: timeZone
            ), monthStart <= target else {
                continue
            }

            let day = (gregorian.dateComponents([.day], from: monthStart, to: target).day ?? -1) + 1
            guard (1...30).contains(day),
                  let labels = hijriLabels(
                    for: monthStart,
                    timeZone: timeZone,
                    officialMonthStarts: officialMonthStarts
                  ) else {
                continue
            }

            return EgyptianAstronomicalEstimate(
                hijriYear: labels.year,
                hijriMonth: labels.month,
                hijriDay: day,
                monthStart: monthStart,
                calculationNote: Self.calculationNote
            )
        }

        return nil
    }

    static func meetsEgyptianVisibilityCriteria(
        conjunction: Date,
        sunset: Date,
        moonset: Date,
        elongationDegrees: Double
    ) -> Bool {
        guard conjunction < sunset,
              moonset.timeIntervalSince(sunset) >= 10 * 60,
              elongationDegrees.isFinite,
              elongationDegrees >= 8 else {
            return false
        }
        return true
    }

    private static let calculationNote =
        "Egyptian astronomical estimate using Dar Al-Ifta's 8° separation and 10-minute moonset-lag criteria at Cairo (30.0444° N, 31.2357° E). Estimated only; not an official Egyptian sighting or announcement."

    private func recentConjunctions(endingAt target: Date) -> [Date] {
        let searchStart = target.addingTimeInterval(-Double(conjunctionSearchDays) * 86_400)
        let step = TimeInterval(conjunctionScanHours * 60 * 60)
        var lower = searchStart
        var lowerPhase = SunCalc.getMoonIllumination(timeAndDate: lower).phase
        var conjunctions: [Date] = []

        while lower < target {
            let upper = min(lower.addingTimeInterval(step), target)
            let upperPhase = SunCalc.getMoonIllumination(timeAndDate: upper).phase

            // SunCalc phase wraps from the waning end of the cycle to zero
            // at astronomical conjunction.
            if lowerPhase > 0.75 && upperPhase < 0.25 {
                conjunctions.append(refineConjunction(between: lower, and: upper))
            }

            lower = upper
            lowerPhase = upperPhase
        }

        return conjunctions
    }

    private func refineConjunction(between lowerBound: Date, and upperBound: Date) -> Date {
        var lower = lowerBound
        var upper = upperBound

        for _ in 0..<32 {
            let midpoint = lower.addingTimeInterval(upper.timeIntervalSince(lower) / 2)
            let phase = SunCalc.getMoonIllumination(timeAndDate: midpoint).phase
            if phase >= 0.5 {
                lower = midpoint
            } else {
                upper = midpoint
            }
        }

        return upper
    }

    private func firstVisibleMonthStart(
        after conjunction: Date,
        timeZone: TimeZone
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let conjunctionDay = calendar.startOfDay(for: conjunction)
        let sameDaySunset = SunCalc.getTimes(
            date: conjunctionDay,
            latitude: latitude,
            longitude: longitude
        ).sunset

        let firstEvening: Date
        if let sameDaySunset, conjunction < sameDaySunset {
            firstEvening = conjunctionDay
        } else {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: conjunctionDay) else {
                return nil
            }
            firstEvening = calendar.startOfDay(for: nextDay)
        }

        for offset in visibilityEveningSearch {
            guard let evening = calendar.date(byAdding: .day, value: offset, to: firstEvening) else {
                continue
            }
            let sunset = SunCalc.getTimes(
                date: evening,
                latitude: latitude,
                longitude: longitude
            ).sunset
            guard let sunset else { continue }

            let moonset = SunCalc.getMoonTimes(
                date: evening,
                latitude: latitude,
                longitude: longitude
            ).set
            guard let moonset else { continue }

            // Evaluate elongation after the minimum ten-minute post-sunset
            // interval used by the cited Egyptian visibility guidance.
            let observationTime = sunset.addingTimeInterval(minimumMoonsetLag)
            let illuminatedFraction = SunCalc.getMoonIllumination(
                timeAndDate: observationTime
            ).fraction
            guard illuminatedFraction.isFinite else { continue }

            let cosine = min(1, max(-1, 1 - 2 * illuminatedFraction))
            let elongationDegrees = acos(cosine) * 180 / Double.pi

            guard Self.meetsEgyptianVisibilityCriteria(
                conjunction: conjunction,
                sunset: sunset,
                moonset: moonset,
                elongationDegrees: elongationDegrees
            ) else {
                continue
            }

            guard let firstCivilDay = calendar.date(byAdding: .day, value: 1, to: evening) else {
                return nil
            }
            return calendar.startOfDay(for: firstCivilDay)
        }

        return nil
    }

    private func hijriLabels(
        for estimatedMonthStart: Date,
        timeZone: TimeZone,
        officialMonthStarts: [EgyptianHijriMonthStart]
    ) -> (year: Int, month: Int)? {
        if let nearestOfficial = officialMonthStarts.min(by: {
            abs($0.gregorianStart.timeIntervalSince(estimatedMonthStart))
                < abs($1.gregorianStart.timeIntervalSince(estimatedMonthStart))
        }), abs(nearestOfficial.gregorianStart.timeIntervalSince(estimatedMonthStart)) <= 3 * 86_400 {
            // Use a nearby official record only to label the month. The
            // estimated start/day still comes from the astronomical calculation.
            return (nearestOfficial.hijriYear, nearestOfficial.hijriMonth)
        }

        var islamic = Calendar(identifier: .islamicCivil)
        islamic.timeZone = timeZone
        let components = islamic.dateComponents([.day, .month, .year], from: estimatedMonthStart)
        guard let day = components.day,
              var month = components.month,
              var year = components.year else {
            return nil
        }

        // If the calculated start precedes the civil-calendar month boundary
        // by a few days, its civil label is still in the previous month.
        if day >= 27 {
            if month == 12 {
                month = 1
                year += 1
            } else {
                month += 1
            }
        }

        return (year, month)
    }
}
