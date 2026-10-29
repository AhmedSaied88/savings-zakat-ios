import Foundation

enum HawlCalculator {
    static var defaultCalendar: Calendar {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        return calendar
    }

    static func dueDate(startDate: Date, calendar: Calendar = defaultCalendar) -> Date? {
        let startOfStart = calendar.startOfDay(for: startDate)
        guard let anniversary = calendar.date(byAdding: .year, value: 1, to: startOfStart) else { return nil }
        return calendar.startOfDay(for: anniversary)
    }

    static func hasCompletedHawl(startDate: Date, asOf: Date, calendar: Calendar = defaultCalendar) -> Bool {
        guard let due = dueDate(startDate: startDate, calendar: calendar) else { return false }
        return calendar.startOfDay(for: asOf) >= due
    }
}