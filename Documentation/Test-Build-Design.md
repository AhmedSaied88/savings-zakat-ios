# Test Build — Unified Asset Ledger and Hawl Reminders

## Purpose
Create a safe, separate native iOS test build of Savings & Zakat. Keep the old PWA and its local records completely separate.

## User-approved direction
- New GitHub repository: AhmedSaied88/savings-zakat-ios.
- Separate test branch: test/asset-ledger-and-hawl-reminders.
- Separate Vercel project container: savings-zakat-ios-test. Vercel is not the native app runtime.
- Test combined Zakat treatment: all included eligible asset values are combined before nisab and 2.5% test.
- Unified table of individual assets and purchases, with per-record acquired date and hawl start.
- Cash/currency popup and gold purchase popup.
- Hawl is measured using one year in Umm al-Qura Islamic calendar, with due date visibly shown.

## Proposed test UX
1. Dashboard: combined total, amount with completed hawl, nisab status, estimated zakat and next upcoming anniversary.
2. Assets: one list, with Add Cash/Currency, Add Gold Purchase, and Add Silver. Each row shows type, amount/weight, currency/carat, acquired/purchase date, hawl start, exact estimated anniversary, and countdown/status. Edit and delete are available.
3. Prices: explicit manual exchange rates and gold/silver resale values with their as-of date. Missing rates/prices mark the calculation provisional.
4. Reminders: request notification permission, schedule 30, 7, 1 day before, and on due date, stable notification identifiers; edits/deletes reschedule/cancel.
5. Combined calculation: combine valued holdings whose hawl is complete, compare eligible wealth with entered nisab in EGP; show calculation line items, assumptions and provisional warnings.

## Technical constraints
- SwiftUI, iOS 17+, native notifications.
- Local-only test storage, versioned schema and migration tests.
- No PWA sync, no use of real data for initial test, no release to App Store.
- Umm al-Qura dates must be validated around month/year/time-zone boundaries; date reminders are estimates.
- iOS local notifications require permission and can be disabled by the user; the UI must show notification authorization status and next due date so the user can verify reminders.
- Avoid using @AppStorage for the entire financial database long-term; use atomic Codable file storage / SwiftData with versioning and export/restore.

## Approaches considered
- Keep existing minimal prototype: fastest but does not satisfy persistent editing, complete silver entry and robust reminders.
- Expand this native SwiftUI app: recommended, retains the correct native platform and current calculation/calendar baseline while filling the missing features.
- Convert to a web/PWA preview: rejected for this repository because the repo is a native iOS app; it would not test the iOS UI or actual notification behavior.

## Non-goals for this test build
- Production financial reliance.
- Replacing the PWA.
- Backend sync or cloud data.
- Automatic live market data until manual calculation/reminder flow is proven.

## Build and test acceptance
- XcodeGen project generation succeeds.
- XCTest passes on macOS CI.
- UI tests cover add/edit/delete, date selection, combined calculation, missing rates, and reminder scheduling/cancellation.
- A simulator build artifact is uploaded for review.
- Physical iPhone install and notification permission/lock-screen behavior are still required before saying reminders are guaranteed.