# Design — Egyptian Savings & Zakat iOS redesign

Date: 2026-10-30
Status: Proposed for user approval; no implementation authorized by this document alone.

## Intent
Build a simple, polished native iPhone app for recording Zakat-relevant holdings, tracking each holding's Hawl, and calculating combined eligible wealth. The app is isolated from the existing Savings & Zakat PWA and must remain free to operate without subscriptions or paid APIs.

## Confirmed user decisions
- Separate native iOS project/repository: `AhmedSaied88/savings-zakat-ios`.
- Visual direction: Design 4's layout and composition with Design 3's blue palette.
- Enter dates as Gregorian dates only; app calculates and displays the corresponding Egyptian Hijri date.
- Use Egyptian lunar calendar dates, not Saudi Umm al-Qura as the source of truth.
- Combine eligible assets for the Zakat calculation, while tracking Hawl dates per holding.
- User wants a simple interface inspired by the supplied wallet and add-account screenshots.
- No subscriptions or paid services.

## Scope
### Included
- Cash and foreign-currency holdings.
- Gold lots (weight, carat, purpose).
- Silver holdings (weight/purity).
- Gregorian acquisition date and Gregorian Hawl-start date input.
- Automatically displayed Egyptian Hijri equivalent and date-confidence status.
- One unified asset list with value, category, acquisition date, Hawl date, countdown, edit and delete.
- Combined Zakat calculation with EGP valuation, Nisab input/reference, completed-Hawl eligible total, 2.5% estimate, transparent breakdown and provisional warnings.
- Local reminders before and on each Hawl anniversary.
- Local durable storage and export/import backup.
- Offline operation; manual exchange rates and metal prices when free reliable data is unavailable.

### Excluded from this release
- Bank SMS reading or automatic bank-account aggregation.
- Credit cards, loans, instalments, money circles, recurring expenses, budgets, or general expense tracking.
- Paid APIs, subscriptions, paid cloud database, or paid notification provider.
- Sync with or migration from the existing PWA.
- Automatic claims that an estimated lunar date is an official Egyptian date.

## Egyptian Gregorian-to-Hijri date policy
- Gregorian date is the only date the user enters.
- Convert using an Egypt-specific calendar service backed by a versioned local date table of Egyptian official month-start announcements.
- For dates covered by verified official Egyptian announcements, show the corresponding Hijri date with status **Officially confirmed** and preserve source/provenance metadata.
- For dates not covered by verified official records (especially future months not yet announced), use a documented astronomical estimate calibrated for Egypt and label it **Estimated**.
- Never silently label a calculated astronomical date as officially confirmed.
- Provide a manual correction mechanism for an official date if an announcement or trusted record is later supplied; record the override and its source.
- Do not depend on network access for conversion. Updates to the local calendar data are optional and must use free/public information; failure to update must not block app usage.
- Calendar conversion must be tested around month boundaries, leap years, time zones, sunset/day-boundary policy, and official date overrides. The product must explicitly document whether the displayed date follows civil midnight or the religious lunar day beginning at sunset; default display is civil-date mapping unless the user approves a different convention.

## Hawl and Zakat behavior
- Each holding stores Gregorian acquisition date and Gregorian Hawl-start date.
- Display its Egyptian Hijri equivalents and its estimated/confirmed status.
- Calculate the holding's one-lunar-year anniversary using the Egyptian calendar mapping, not a fixed 354-day approximation and not Umm al-Qura.
- Track each holding's maturity separately, then combine eligible matured holdings for the selected combined-calculation method.
- Convert values to EGP using user-entered rates/prices. Missing values produce visible warnings and a provisional result, never a blocked calculation.
- Show calculation inputs, included/excluded holdings, Nisab comparison and arithmetic. Treat this as a configurable test method, not a universal religious ruling.

## Visual direction
- Native SwiftUI and iOS navigation patterns.
- Composition inspired by Design 4: compact dashboard, distinct asset-entry tiles, clear Zakat screen, and dedicated Hawl calendar.
- Palette from Design 3: clean white and pale-blue backgrounds, royal-blue primary actions, restrained violet secondary accents, gold asset accents, semantic status colors.
- Avoid dense card stacks; use clear hierarchy, compact rows, readable totals, and generous touch targets.
- Screens:
  1. Home / overview: eligible wealth, Nisab status, asset breakdown, upcoming Hawl, quick add actions.
  2. Assets: unified searchable/filterable list and holding detail/edit.
  3. Add holding: choose Cash, Currency, Gold, or Silver; concise type-specific form.
  4. Zakat: transparent combined calculation and warnings.
  5. Hawl calendar: upcoming anniversaries, Hijri/Gregorian dates and confirmation status.
  6. Settings: manual rates/prices, calendar-data status, reminder permission, backup/restore.
- Date fields use native Gregorian date pickers. After selection, show the calculated Egyptian Hijri date immediately.

## Free operation and privacy
- All calculations, storage, date conversion, and reminders run on device.
- No account registration, paid API, subscription, or required cloud backend.
- Local notifications only; delivery depends on iOS permission and device settings.
- Backup/restore is user-controlled local file export/import.
- Never upload financial records without separate explicit consent.

## Approaches considered
1. **Egyptian official-date hybrid (selected):** locally bundled official Egyptian month-start records where verified; Egypt-calibrated astronomical estimates for uncovered dates; clear status labels and manual correction. Best balance of Egyptian relevance, offline operation and honesty about uncertainty.
2. **Astronomical-only Egyptian estimate:** fully algorithmic and offline, but can differ from official Egyptian announcements; rejected as sole source of truth.
3. **Saudi Umm al-Qura calendar:** easy to use as a bundled calendar but does not meet the user's Egypt-specific requirement; rejected.

## Constraints and open implementation decisions
- A complete, trustworthy historical Egyptian official-date dataset must be sourced or curated before dates can be labelled officially confirmed. If unavailable, dates remain Estimated until verified.
- Future month starts cannot be confirmed before the relevant Egyptian announcement.
- The exact sunset-vs-civil-date convention must be made explicit in the UI and tests; use civil Gregorian date mapping as the initial display default.
- Nisab reference method and personal-use gold treatment should remain visible/configurable rather than hidden assumptions.
- Native iPhone installation with Xcode and a free Apple account may be possible for testing, but App Store distribution requires Apple's paid developer membership; no paid distribution is included.

## Acceptance criteria
- User can add/edit/delete cash, currency, gold and silver holdings.
- Every date is entered in Gregorian format and an Egyptian Hijri equivalent appears immediately.
- Every Hijri result is labelled Officially confirmed or Estimated with no false certainty.
- Hawl dates and reminders are computed from the Egyptian date mapping and independently tested at boundaries.
- Combined calculation works offline even when rates/prices are missing; missing inputs are clearly marked provisional.
- Data persists across app relaunch and can be backed up/restored locally.
- Automated tests pass; physical iPhone testing is documented before any production-use claim.
- Existing PWA and its data remain untouched.
