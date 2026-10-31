# Egyptian calendar sources and confidence policy

## Primary authority

The bundled official month-start records are transcribed from Egypt's Dar Al-Ifta announcement pages. Dar Al-Ifta describes its role as determining the beginning and end of lunar months through seven committees distributed across Egypt, with scholars and astronomy specialists. The committees perform observations on the 29th day and the Grand Mufti announces the result.

- English overview: https://www.dar-alifta.org/en/service/lunar-months-moon-sighting
- Arabic Hijri date service and institutional description: https://www.dar-alifta.org/ar/services/Details/12/التاريخ-الهجري
- Dar Al-Ifta's explanation of the method: https://www.dar-alifta.org/ar/fatwa/details/16129/طرق-معرفة-بداية-الشهر-العربي-في-التقويم-الهجري
- Dar Al-Ifta's explanation of the role of astronomical calculation: https://dar-alifta.org/ar/fatwa/details/16131/الاستئناس-بالحسابات-الفلكية-في-إثبات-الهلال-شرعًا

The cited guidance says the month is established by crescent sighting; astronomical calculation may be used to rule out an impossible sighting but is not, by itself, the religious confirmation. Therefore the app must not turn a calculated prediction into an official Egyptian month start.

## Bundled dataset

Dataset version: `2026.10.2`

The dataset includes five consecutive official announcements for 1448 AH:

| Hijri month | First Gregorian day | Announcement date | Dar Al-Ifta record |
|---|---:|---:|---|
| Muharram 1448 | 2026-06-16 | 2026-06-15 | https://www.dar-alifta.org/ar/articles/details/11188/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-المحرم-لعام-1448هـ |
| Safar 1448 | 2026-07-15 | 2026-07-14 | https://dar-alifta.org/ar/articles/details/12259/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-صفر-لعام-1448هـ |
| Rabi' al-Awwal 1448 | 2026-08-14 | 2026-08-12 | https://dar-alifta.org/ar/articles/details/12309/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الأول-لعام-1448هـ |
| Rabi' al-Thani 1448 | 2026-09-13 | 2026-09-11 | https://www.dar-alifta.org/ar/articles/details/12415/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الآخر-لعام-1448هـ |
| Jumada al-Awwal 1448 | 2026-10-12 | 2026-10-11 | https://www.dar-alifta.org/ar/articles/details/12468/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الأولى-لعام-1448هـ |

Each row is an announcement-backed month start, not a forecast. The source page and announcement date are retained in `EgyptianHijriMonthStart`.

## Expanded official records (2026-10-31 review)

The dataset now also contains primary-source announcements for 1447 AH. The following dates are copied from the first-day declarations in the linked Dar Al-Ifta announcements:

| Hijri month | First Gregorian day | Announcement date | Dar Al-Ifta record |
|---|---:|---:|---|
| Muharram 1447 | 2025-06-26 | 2025-06-25 | https://www.dar-alifta.org/ar/articles/details/10277/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-المحرم-لعام-1447هـ |
| Safar 1447 | 2025-07-26 | 2025-07-24 | https://www.dar-alifta.org/ar/articles/details/10353/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-صفر-لعام-1447هـ |
| Rabi' al-Awwal 1447 | 2025-08-24 | 2025-08-23 | https://www.dar-alifta.org/ar/articles/details/10466/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الأول-لعام-1447هـ |
| Rabi' al-Thani 1447 | 2025-09-23 | 2025-09-21 | https://www.dar-alifta.org/ar/articles/details/10558/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ربيع-الآخر-لعام-1447هـ |
| Jumada al-Awwal 1447 | 2025-10-23 | 2025-10-21 | https://www.dar-alifta.org/ar/articles/details/10643/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الأولى-لعام-1447هـ |
| Jumada al-Thani 1447 | 2025-11-22 | 2025-11-20 | https://www.dar-alifta.org/ar/articles/details/10727/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-جمادى-الآخرة-لعام-1447هـ |
| Rajab 1447 | 2025-12-21 | 2025-12-20 | https://www.dar-alifta.org/ar/articles/details/10846/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-رجب-لعام-1447هـ |
| Sha'ban 1447 | 2026-01-20 | 2026-01-18 | https://www.dar-alifta.org/ar/articles/details/10915/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-شعبان-لعام-1447هـ |
| Ramadan 1447 | 2026-02-19 | 2026-02-17 | https://www.dar-alifta.org/ar/articles/details/11039/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-رمضان-لعام-1447هـ |
| Dhu al-Qi'dah 1447 | 2026-04-19 | 2026-04-17 | https://dar-alifta.org/ar/articles/details/11112/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ذي-القعدة-لعام-1447هـ |
| Dhu al-Hijjah 1447 | 2026-05-18 | 2026-05-17 | https://dar-alifta.org/ar/articles/details/11149/بيان-دار-الإفتاء-المصرية-حول-رؤية-هلال-شهر-ذي-الحجة-لعام-1447هـ |

**Deliberate gap:** No 1447 AH Shawwal record is bundled in this revision because its primary Dar Al-Ifta announcement was not independently located during this review. The calendar does not infer or fill that missing month from arithmetic. As a result, the adjacent 1447 Ramadan and Dhu al-Qi'dah records do not form a continuous confirmed interval. Dhu al-Hijjah 1447 and Muharram 1448 are adjacent and do form a confirmed boundary.

## Coverage limits

This is a partial, intentionally transparent dataset (16 source-backed starts across 1447–1448 AH). It is **not** a complete Egyptian historical calendar. The implementation marks dates as officially confirmed only inside an interval whose current and next month starts are both in the bundled source table. The first day of the latest announced month can be marked confirmed on that date alone; later days in that month remain Estimated until the next Egyptian announcement is added.

Dates before the first bundled month, dates after the last covered day, and future months not yet announced use the system's Islamic-civil fallback and are labelled **Estimated**. This fallback is an approximation, not a claim that the Islamic-civil calendar is Egypt's official calendar.

No network connection is required at runtime. Adding more official dates means transcribing a dated Dar Al-Ifta announcement, checking the Hijri year/month and Gregorian date, adding its source URL and announcement date, and incrementing the dataset version. Do not import Saudi Umm al-Qura dates as Egyptian confirmed records.

## Date convention

The app accepts Gregorian dates. The current conversion maps civil Gregorian calendar days in the Africa/Cairo time zone; it does not attempt to shift a date at sunset. This civil-date convention must remain explicit in the UI and documentation. Hawl anniversary confidence is Confirmed only when the corresponding Egyptian month-start boundaries for both years are available; otherwise it is Estimated.
