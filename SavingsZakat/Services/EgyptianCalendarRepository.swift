import Foundation

/// Bundled Egyptian month-start announcements. This is a deliberately limited,
/// versioned seed dataset, not a complete historical calendar.
enum EgyptianCalendarRepository {
    static let dataVersion = "2026.10.2"

    static let officialMonthStarts: [EgyptianHijriMonthStart] = [
        // 1447 AH: Dar Al-Ifta announcements, source-backed Egyptian starts.
        record(1447, 1, "2025-06-26", "2025-06-25",
               "https://www.dar-alifta.org/ar/articles/details/10277/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-المحرم-لعام-1447هـ"),
        record(1447, 2, "2025-07-26", "2025-07-24",
               "https://www.dar-alifta.org/ar/articles/details/10353/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-صفر-لعام-1447هـ"),
        record(1447, 3, "2025-08-24", "2025-08-23",
               "https://www.dar-alifta.org/ar/articles/details/10466/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الأول-لعام-1447هـ"),
        record(1447, 4, "2025-09-23", "2025-09-21",
               "https://www.dar-alifta.org/ar/articles/details/10558/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الآخر-لعام-1447هـ"),
        record(1447, 5, "2025-10-23", "2025-10-21",
               "https://www.dar-alifta.org/ar/articles/details/10643/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الأولى-لعام-1447هـ"),
        record(1447, 6, "2025-11-22", "2025-11-20",
               "https://www.dar-alifta.org/ar/articles/details/10727/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الآخرة-لعام-1447هـ"),
        record(1447, 7, "2025-12-21", "2025-12-20",
               "https://www.dar-alifta.org/ar/articles/details/10846/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-رجب-لعام-1447هـ"),
        record(1447, 8, "2026-01-20", "2026-01-18",
               "https://www.dar-alifta.org/ar/articles/details/10915/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-شعبان-لعام-1447هـ"),
        record(1447, 9, "2026-02-19", "2026-02-17",
               "https://www.dar-alifta.org/ar/articles/details/11039/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-رمضان-لعام-1447هـ"),
        // Shawwal 1447 is intentionally absent: its primary announcement was
        // not independently located in this source review, so no boundary is inferred.
        record(1447, 11, "2026-04-19", "2026-04-17",
               "https://dar-alifta.org/ar/articles/details/11112/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ذي-القعدة-لعام-1447هـ"),
        record(1447, 12, "2026-05-18", "2026-05-17",
               "https://dar-alifta.org/ar/articles/details/11149/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ذي-الحجة-لعام-1447هـ"),
        // 1448 AH
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
