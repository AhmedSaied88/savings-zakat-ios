import Foundation

enum HijriDateStatus: String, Codable, Equatable {
    case officiallyConfirmed
    case estimated
}

struct EgyptianHijriMonthStart: Codable, Equatable {
    var hijriYear: Int
    var hijriMonth: Int
    var gregorianStart: Date
    var sourceURL: String
    var announcementDate: Date

    init(hijriYear: Int, hijriMonth: Int, gregorianStart: Date, sourceURL: String, announcementDate: Date) {
        self.hijriYear = hijriYear
        self.hijriMonth = hijriMonth
        self.gregorianStart = gregorianStart
        self.sourceURL = sourceURL
        self.announcementDate = announcementDate
    }
}

struct EgyptianHijriDate: Equatable {
    var hijriYear: Int
    var hijriMonth: Int
    var hijriDay: Int
    var status: HijriDateStatus
    var sourceURL: String?
    var calculationNote: String? = nil
}

struct EgyptianHijriCalendar {
    private let officialMonthStarts: [EgyptianHijriMonthStart]
    private let timeZone: TimeZone

    init(officialMonthStarts: [EgyptianHijriMonthStart], timeZone: TimeZone = TimeZone(identifier: "Africa/Cairo") ?? .current) {
        self.officialMonthStarts = officialMonthStarts.sorted { $0.gregorianStart < $1.gregorianStart }
        self.timeZone = timeZone
    }

    func convert(_ gregorianDate: Date) -> EgyptianHijriDate? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let target = gregorian.startOfDay(for: gregorianDate)

        for index in officialMonthStarts.indices {
            let current = officialMonthStarts[index]
            let start = gregorian.startOfDay(for: current.gregorianStart)
            if index + 1 < officialMonthStarts.count {
                let next = officialMonthStarts[index + 1]
                if Self.isImmediateNextMonth(after: current, before: next) {
                    let end = gregorian.startOfDay(for: next.gregorianStart)
                    guard target >= start && target < end else { continue }
                    let day = gregorian.dateComponents([.day], from: start, to: target).day ?? 0
                    return EgyptianHijriDate(
                        hijriYear: current.hijriYear,
                        hijriMonth: current.hijriMonth,
                        hijriDay: day + 1,
                        status: .officiallyConfirmed,
                        sourceURL: current.sourceURL
                    )
                } else if target == start {
                    return EgyptianHijriDate(
                        hijriYear: current.hijriYear,
                        hijriMonth: current.hijriMonth,
                        hijriDay: 1,
                        status: .officiallyConfirmed,
                        sourceURL: current.sourceURL
                    )
                }
            } else if target == start {
                // The announced first day is confirmed even before the following
                // month's announcement is available. Later days remain estimated.
                return EgyptianHijriDate(
                    hijriYear: current.hijriYear,
                    hijriMonth: current.hijriMonth,
                    hijriDay: 1,
                    status: .officiallyConfirmed,
                    sourceURL: current.sourceURL
                )
            }
        }

        if let astronomical = EgyptianAstronomicalEstimator().estimate(
            containing: target,
            timeZone: timeZone,
            officialMonthStarts: officialMonthStarts
        ) {
            return EgyptianHijriDate(
                hijriYear: astronomical.hijriYear,
                hijriMonth: astronomical.hijriMonth,
                hijriDay: astronomical.hijriDay,
                status: .estimated,
                sourceURL: nil,
                calculationNote: astronomical.calculationNote
            )
        }

        // Retain a labelled arithmetic fallback if the astronomical engine
        // cannot calculate a usable sunset/moonset event for the reference date.
        var estimate = Calendar(identifier: .islamicCivil)
        estimate.timeZone = timeZone
        let components = estimate.dateComponents([.day, .month, .year], from: target)
        guard let day = components.day, let month = components.month, let year = components.year else { return nil }
        return EgyptianHijriDate(
            hijriYear: year,
            hijriMonth: month,
            hijriDay: day,
            status: .estimated,
            sourceURL: nil,
            calculationNote: "Islamic-civil arithmetic fallback because the Cairo astronomical estimate was unavailable; not an official Egyptian announcement."
        )
    }

    private static func isImmediateNextMonth(after current: EgyptianHijriMonthStart, before next: EgyptianHijriMonthStart) -> Bool {
        let expectedYear = current.hijriMonth == 12 ? current.hijriYear + 1 : current.hijriYear
        let expectedMonth = current.hijriMonth == 12 ? 1 : current.hijriMonth + 1
        return next.hijriYear == expectedYear && next.hijriMonth == expectedMonth
    }

    /// Returns the same Hijri month/day in the following year only when both
    /// official month boundaries are present in the source-backed dataset.
    func anniversary(of gregorianDate: Date) -> HawlDueDate? {
        guard let original = convert(gregorianDate) else { return nil }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone

        if original.status == .officiallyConfirmed,
           let targetIndex = officialMonthStarts.firstIndex(where: {
               $0.hijriYear == original.hijriYear + 1 && $0.hijriMonth == original.hijriMonth
           }),
           targetIndex + 1 < officialMonthStarts.count,
           Self.isImmediateNextMonth(
               after: officialMonthStarts[targetIndex],
               before: officialMonthStarts[targetIndex + 1]
           ) {
            let monthStart = gregorian.startOfDay(for: officialMonthStarts[targetIndex].gregorianStart)
            let nextStart = gregorian.startOfDay(for: officialMonthStarts[targetIndex + 1].gregorianStart)
            let monthLength = gregorian.dateComponents([.day], from: monthStart, to: nextStart).day ?? 0
            guard monthLength > 0 else { return nil }
            let day = min(original.hijriDay, monthLength)
            guard let date = gregorian.date(byAdding: .day, value: day - 1, to: monthStart) else { return nil }
            return HawlDueDate(date: date, status: .officiallyConfirmed)
        }

        var estimate = Calendar(identifier: .islamicCivil)
        estimate.timeZone = timeZone
        let start = gregorian.startOfDay(for: gregorianDate)
        guard let date = estimate.date(byAdding: .year, value: 1, to: start) else { return nil }
        return HawlDueDate(date: gregorian.startOfDay(for: date), status: .estimated)
    }
}
