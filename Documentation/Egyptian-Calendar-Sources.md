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

This is a partial, intentionally transparent dataset (16 source-backed starts across 1447–1448 AH). It is **not** a complete Egyptian historical calendar. The implementation marks dates as officially confirmed only inside an interval whose current and next month starts are both in the bundled source table. The first day of the latest announced month can be marked confirmed on that date alone. Later days remain Estimated; while still within that announced month, the app uses its first day as the provisional day-count anchor. The possible 29-day rollover is checked astronomically before day 30 is assigned.

Dates before the first bundled month, dates after the last covered day, and future months not yet announced use the system's Islamic-civil fallback and are labelled **Estimated**. This fallback is an approximation, not a claim that the Islamic-civil calendar is Egypt's official calendar.

No network connection is required at runtime. Adding more official dates means transcribing a dated Dar Al-Ifta announcement, checking the Hijri year/month and Gregorian date, adding its source URL and announcement date, and incrementing the dataset version. Do not import Saudi Umm al-Qura dates as Egyptian confirmed records.

## Egyptian astronomical estimate for uncovered dates

The offline estimate uses the criteria described in Dar Al-Ifta fatwa No. 2345, dated 10 December 2011:

- The conjunction must occur before the local sunset.
- The crescent's angular separation from the Sun must be at least 8°.
- The Moon must set at least 10 minutes after sunset.

The app calculates the conjunction from the lunar phase, then evaluates the first three possible Cairo evenings after conjunction. It checks the elongation at sunset plus ten minutes and uses the calculated moonset to test the minimum lag. The next civil Gregorian day after the first passing observation evening is used as the estimated month start.

The calculation uses the open-source MIT-licensed [SunCalc Swift implementation](https://github.com/Timac/SunCalc), pinned to revision `7e8ad5cbdf2742fb68527612ba6bf78e7f55dfe0`. The package performs calculations on-device; no network request or runtime data download is used. The reference coordinate is Cairo (30.0444° N, 31.2357° E), and the app retains the Africa/Cairo civil-day convention.

**Important limitations:** Dar Al-Ifta describes observation committees at multiple locations across Egypt. This implementation models one Cairo reference point and does not model all committee sites, local atmospheric conditions, observer skill, or an actual sighting. It is therefore always labelled **Estimated** and must never be used as an official Egyptian calendar declaration. A separate Dar Al-Ifta publication describes a 15-hour-40-minute condition; this implementation does not combine that separate criterion with the 8°/10-minute method above.

If the astronomy engine cannot provide a valid conjunction, sunset, moonset, or month boundary, conversion falls back to the clearly labelled Islamic-civil arithmetic estimate. Official Dar Al-Ifta intervals are evaluated before this estimator and are unchanged.

## Date convention

The app accepts Gregorian dates. The current conversion maps civil Gregorian calendar days in the Africa/Cairo time zone; it does not attempt to shift a date at sunset. This civil-date convention must remain explicit in the UI and documentation. Hawl anniversary confidence is Confirmed only when the corresponding Egyptian month-start boundaries for both years are available; otherwise it is Estimated.
