# Egyptian calendar sources and confidence policy

## Primary authority

The bundled official month-start records are transcribed from Egypt's Dar Al-Ifta announcement pages. Dar Al-Ifta describes its role as determining the beginning and end of lunar months through seven committees distributed across Egypt, with scholars and astronomy specialists. The committees perform observations on the 29th day and the Grand Mufti announces the result.

- English overview: https://www.dar-alifta.org/en/service/lunar-months-moon-sighting
- Arabic Hijri date service and institutional description: https://www.dar-alifta.org/ar/services/Details/12/التاريخ-الهجري
- Dar Al-Ifta's explanation of the method: https://www.dar-alifta.org/ar/fatwa/details/16129/طرق-معرفة-بداية-الشهر-العربي-في-التقويم-الهجري
- Dar Al-Ifta's explanation of the role of astronomical calculation: https://dar-alifta.org/ar/fatwa/details/16131/الاستئناس-بالحسابات-الفلكية-في-إثبات-الهلال-شرعًا

The cited guidance says the month is established by crescent sighting; astronomical calculation may be used to rule out an impossible sighting but is not, by itself, the religious confirmation. Therefore the app must not turn a calculated prediction into an official Egyptian month start.

## Bundled dataset

Dataset version: `2026.10.1`

The first bundled seed contains five consecutive official announcements for 1448 AH:

| Hijri month | First Gregorian day | Announcement date | Dar Al-Ifta record |
|---|---:|---:|---|
| Muharram 1448 | 2026-06-16 | 2026-06-15 | https://www.dar-alifta.org/ar/articles/details/11188/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-المحرم-لعام-1448هـ |
| Safar 1448 | 2026-07-15 | 2026-07-14 | https://dar-alifta.org/ar/articles/details/12259/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-صفر-لعام-1448هـ |
| Rabi' al-Awwal 1448 | 2026-08-14 | 2026-08-12 | https://dar-alifta.org/ar/articles/details/12309/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الأول-لعام-1448هـ |
| Rabi' al-Thani 1448 | 2026-09-13 | 2026-09-11 | https://www.dar-alifta.org/ar/articles/details/12415/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الآخر-لعام-1448هـ |
| Jumada al-Awwal 1448 | 2026-10-12 | 2026-10-11 | https://www.dar-alifta.org/ar/articles/details/12468/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الأولى-لعام-1448هـ |

Each row is an announcement-backed month start, not a forecast. The source page and announcement date are retained in `EgyptianHijriMonthStart`.

## Coverage limits

This is a small, intentionally transparent seed dataset. It is **not** a complete Egyptian historical calendar. The implementation marks dates as officially confirmed only inside an interval whose current and next month starts are both in the bundled source table. The first day of the latest announced month can be marked confirmed on that date alone; later days in that month remain Estimated until the next Egyptian announcement is added.

Dates before the first bundled month, dates after the last covered day, and future months not yet announced use the system's Islamic-civil fallback and are labelled **Estimated**. This fallback is an approximation, not a claim that the Islamic-civil calendar is Egypt's official calendar.

No network connection is required at runtime. Adding more official dates means transcribing a dated Dar Al-Ifta announcement, checking the Hijri year/month and Gregorian date, adding its source URL and announcement date, and incrementing the dataset version. Do not import Saudi Umm al-Qura dates as Egyptian confirmed records.

## Date convention

The app accepts Gregorian dates. The current conversion maps civil Gregorian calendar days in the Africa/Cairo time zone; it does not attempt to shift a date at sunset. This civil-date convention must remain explicit in the UI and documentation. Hawl anniversary confidence is Confirmed only when the corresponding Egyptian month-start boundaries for both years are available; otherwise it is Estimated.
