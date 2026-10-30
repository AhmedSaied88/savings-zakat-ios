# Design — Egyptian Savings & Zakat iOS redesign

Date: 2026-10-30
Status: Proposed for user approval; no implementation authorized by this document alone.

## Intent
Build a polished native iPhone personal-finance app with wallet, bank/SMS transaction capture, debit and credit cards, cash, savings, mobile wallets, assets, debts, instalments, and an integrated Egyptian-calendar Savings & Zakat module. The app is isolated from the existing Savings & Zakat PWA and must remain free to operate without subscriptions or paid APIs.

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
- Wallet overview with net worth, spendable balance, savings, assets, and amounts owed.
- Bank accounts with manually maintained balances and transaction history.
- iPhone-only bank SMS capture through Apple Shortcuts personal automations where supported: a Message-received automation filters by sender and/or text, passes the message text to the app through a local URL/deep-link or App Intent, and the app parses it on-device into a proposed transaction. Require user review/confirmation by default, with an optional trusted-rule workflow only after explicit configuration. Provide a manual share/paste fallback and editable bank-format rules.
- A setup guide and ready-to-import Shortcut instructions/templates for supported Egyptian bank SMS formats; users configure the sender/keyword filters and grant required Shortcuts permissions on their own iPhone.
- Debit cards linked to bank accounts, with masked card details only; never store PIN, CVV, full card number, or online-banking credentials.
- Credit cards with issuer/name, masked last four digits, credit limit, current balance, statement date, payment due date, minimum due, and payment tracking.
- Cash accounts, mobile wallets, prepaid cards, savings pots, and manual investments.
- Loans, instalments/Buy Now Pay Later, and other liabilities with outstanding balance, due dates, and payment history.
- Transaction categorization, transfers between owned accounts, income/expense tracking, search and filters, and monthly summaries.
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

### Platform limitations and exclusions
- The app itself cannot directly read the iPhone SMS inbox. Shortcuts is the user-authorized automation bridge: availability, trigger behavior, permissions, and whether a message automation can run without confirmation depend on iOS version and the user's Shortcuts configuration. Do not promise universal silent/background delivery. Include share/paste/manual fallback.
- No direct bank-account API aggregation unless a genuinely free, supported provider is verified; default to manual accounts and user-shared SMS.
- No storing card PINs, CVVs, full PANs, banking passwords, or OTPs. Detect and discard/redact sensitive authentication data from imported messages.
- No paid subscription, paid API, paid cloud database, or paid notification provider.
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
  1. Home / Wallet: net worth, spendable, savings, assets, owed, quick actions and recent activity.
  2. Accounts & Cards: bank accounts, debit cards, credit cards, cash, mobile wallets and prepaid cards.
  3. Transactions: Shortcuts-captured SMS inbox, parsed transaction review, categories, transfers, recurring items, search and monthly summaries.
  4. Add Account: simple category tiles inspired by the supplied reference, with concise forms.
  5. Assets: unified cash/currency/gold/silver/investment list and holding detail/edit.
  6. Debts: loans, instalments, credit-card liabilities and payment due dates.
  7. Zakat: transparent combined calculation and warnings.
  8. Hawl calendar: upcoming anniversaries, Hijri/Gregorian dates and confirmation status.
  9. Settings: Shortcuts setup and bank message parsing rules, manual rates/prices, calendar-data status, reminder permission, privacy and backup/restore.
- Date fields use native Gregorian date pickers. After selection, show the calculated Egyptian Hijri date immediately.

## Free operation and privacy
- All calculations, storage, date conversion, SMS parsing, and reminders run on device.
- No account registration, paid API, subscription, or required cloud backend.
- Local notifications only; delivery depends on iOS permission and device settings.
- Backup/restore is user-controlled local file export/import.
- Never upload financial records without separate explicit consent.
- Imported SMS content is processed locally; redact OTPs, PINs, CVVs and other authentication secrets immediately. Store only the confirmed transaction fields and a minimal redacted source excerpt if the user opts in.
- Use masked card references only. No payment processing or bank credential collection.

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
- User can create/edit/delete bank accounts, cash, mobile wallets, debit and credit cards, savings, investments, loans and instalment records.
- User can configure an iOS Shortcuts message automation to pass selected bank SMS messages into the app; supported formats are parsed into a review screen, and no transaction is posted without confirmation by default.
- Manual share/paste remains available when an automation trigger or bank format is unsupported.
- Duplicate SMS imports are detected; transfers between owned accounts do not inflate income or expenses.
- Card numbers are masked and sensitive authentication data is never retained.
- User can add/edit/delete cash, currency, gold and silver holdings.
- Every date is entered in Gregorian format and an Egyptian Hijri equivalent appears immediately.
- Every Hijri result is labelled Officially confirmed or Estimated with no false certainty.
- Hawl dates and reminders are computed from the Egyptian date mapping and independently tested at boundaries.
- Combined calculation works offline even when rates/prices are missing; missing inputs are clearly marked provisional.
- Data persists across app relaunch and can be backed up/restored locally.
- Automated tests pass; physical iPhone testing is documented before any production-use claim.
- Existing PWA and its data remain untouched.
