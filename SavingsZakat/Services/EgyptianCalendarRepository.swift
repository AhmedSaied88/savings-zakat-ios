import Foundation

/// Bundled Egyptian month-start announcements. This is a deliberately limited,
/// versioned seed dataset, not a complete historical calendar.
enum EgyptianCalendarRepository {
    static let dataVersion = "2026.10.1"

    static let officialMonthStarts: [EgyptianHijriMonthStart] = [
        record(1448, 1, "2026-06-16", "2026-06-15",
               "https://www.dar-alifta.org/ar/articles/details/11188/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-المحرم-لعام-1448هـ"),
        record(1448, 2, "2026-07-15", "2026-07-14",
               "https://dar-alifta.org/ar/articles/details/12259/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-صفر-لعام-1448هـ"),
        record(1448, 3, "2026-08-14", "2026-08-12",
               "https://dar-alifta.org/ar/articles/details/12309/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الأول-لعام-1448هـ"),
        record(1448, 4, "2026-09-13", "2026-09-11",
               "https://www.dar-alifta.org/ar/articles/details/12415/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الآخر-لعام-1448هـ"),
        record(1448, 5, "2026-10-12", "2026-10-11",
               "https://www.dar-alifta.org/ar/articles/details/12468/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الأولى-لعام-1448هـ")
    ]

    static func makeCalendar(
        timeZone: TimeZone = TimeZone(identifier: "Africa/Cairo") ?? .current
    ) -> EgyptianHijriCalendar {
        EgyptianHijriCalendar(officialMonthStarts: officialMonthStarts, timeZone: timeZone)
    }

    private static func record(
        _ year: Int,
        _ month: Int,
        _ start: String,
        _ announced: String,
        _ source: String
    ) -> EgyptianHijriMonthStart {
        EgyptianHijriMonthStart(
            hijriYear: year,
            hijriMonth: month,
            gregorianStart: date(start),
            sourceURL: source,
            announcementDate: date(announced)
        )
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
