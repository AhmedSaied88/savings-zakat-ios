import Foundation

struct HawlDueDate: Equatable {
    let date: Date
    let status: HijriDateStatus
}

enum HawlCalculator {
    /// Egyptian official month-start records are injected when available.
    /// Without a complete official month interval, the anniversary is explicitly estimated.
    static func dueDateResult(
        startDate: Date,
        egyptianCalendar: EgyptianHijriCalendar = EgyptianHijriCalendar(officialMonthStarts: []),
        fallbackTimeZone: TimeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
    ) -> HawlDueDate? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = fallbackTimeZone
        let start = gregorian.startOfDay(for: startDate)

        if let hijri = egyptianCalendar.convert(startDate),
           hijri.status == .officiallyConfirmed {
            // An official anniversary is only calculable if the matching month in
            // the following Hijri year and the following month boundary are known.
            // The current data provider exposes conversion, not inverse conversion;
            // therefore never label a civil-calendar approximation as official.
            _ = hijri
        }

        var estimateCalendar = Calendar(identifier: .islamicCivil)
        estimateCalendar.timeZone = fallbackTimeZone
        guard let anniversary = estimateCalendar.date(byAdding: .year, value: 1, to: start) else { return nil }
        return HawlDueDate(date: gregorian.startOfDay(for: anniversary), status: .estimated)
    }

    /// Compatibility helper. The date is an estimate unless an official Egyptian
    /// month-start dataset and inverse anniversary mapping are available.
    static func dueDate(startDate: Date, calendar: Calendar? = nil) -> Date? {
        var selected = calendar ?? Calendar(identifier: .islamicCivil)
        if calendar == nil { selected.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current }
        let day = selected.startOfDay(for: startDate)
        guard let anniversary = selected.date(byAdding: .year, value: 1, to: day) else { return nil }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = selected.timeZone
        return gregorian.startOfDay(for: anniversary)
    }

    static func hasCompletedHawl(startDate: Date, asOf: Date, calendar: Calendar? = nil) -> Bool {
        guard let due = dueDate(startDate: startDate, calendar: calendar) else { return false }
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar?.timeZone ?? (TimeZone(identifier: "Africa/Cairo") ?? .current)
        return gregorian.startOfDay(for: asOf) >= due
    }
}
