import Foundation

struct HawlDueDate: Equatable {
    let date: Date
    let status: HijriDateStatus
}

enum HawlCalculator {
    /// Computes a one-lunar-year anniversary from Egyptian month records where
    /// both years are covered. Otherwise returns an explicitly estimated date.
    static func dueDateResult(
        startDate: Date,
        egyptianCalendar: EgyptianHijriCalendar = EgyptianCalendarRepository.makeCalendar()
    ) -> HawlDueDate? {
        egyptianCalendar.anniversary(of: startDate)
    }

    static func dueDate(
        startDate: Date,
        egyptianCalendar: EgyptianHijriCalendar = EgyptianCalendarRepository.makeCalendar()
    ) -> Date? {
        dueDateResult(startDate: startDate, egyptianCalendar: egyptianCalendar)?.date
    }

    static func hasCompletedHawl(
        startDate: Date,
        asOf: Date,
        egyptianCalendar: EgyptianHijriCalendar = EgyptianCalendarRepository.makeCalendar()
    ) -> Bool {
        guard let due = dueDateResult(startDate: startDate, egyptianCalendar: egyptianCalendar) else {
            return false
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
        return calendar.startOfDay(for: asOf) >= calendar.startOfDay(for: due.date)
    }
}
