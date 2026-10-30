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
            guard index + 1 < officialMonthStarts.count else { continue }
            let next = officialMonthStarts[index + 1]
            let start = gregorian.startOfDay(for: current.gregorianStart)
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
        }

        var estimate = Calendar(identifier: .islamicCivil)
        estimate.timeZone = timeZone
        let components = estimate.dateComponents([.day, .month, .year], from: target)
        guard let day = components.day, let month = components.month, let year = components.year else { return nil }
        return EgyptianHijriDate(hijriYear: year, hijriMonth: month, hijriDay: day, status: .estimated, sourceURL: nil)
    }
}
