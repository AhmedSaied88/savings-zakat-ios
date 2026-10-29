# Design Specification — Savings & Zakat iOS

Status: isolated prototype; not a production release.

## Approved direction
- Native SwiftUI iPhone app in a separate repository and bundle identifier.
- One unified asset list for cash, foreign currency, gold lots, and silver.
- Cash entry: amount, currency, acquired date, and hawl-start date.
- Gold entry: grams, carat, purchase date, hawl-start date, and purpose.
- Combined calculation: convert valued holdings to EGP, sum holdings with completed hawl, compare with nisab, and estimate 2.5% when the configured test conditions are met.
- Use the Islamic Umm al-Qura calendar for estimated lunar-year anniversaries.
- Missing exchange rates or prices must be visible and make results provisional.
- Local-only test data; no PWA sync or migration.
- Reminder defaults planned for 30, 7, and 1 day before the anniversary and on the due date.
- No production replacement without a successful build/test, physical-device validation, and explicit user approval.

## Current prototype limitations
The present source uses app-local UserDefaults JSON, manual test rates, and manual gold/silver prices. It does not yet implement silver entry, edit actions, scheduled local notifications, encrypted backup/restore, or UI tests. A successful macOS/Xcode build is not yet confirmed. Do not use real financial records or rely on its output as religious or financial advice.
