# Architecture

## App boundary

This is a separate iPhone-only SwiftUI application. It does not share storage, authentication, deployment, or data with the existing Savings & Zakat PWA. The PWA repository and its production deployment are outside this app's scope and must remain untouched.

## Layers

- **Presentation:** SwiftUI tab screens and entry forms. Views submit validated operations to domain services and persist returned snapshots; they do not calculate transaction balances independently.
- **Domain models:** Accounts, payment cards, transactions, liabilities, holdings, money values, preferences, imported messages, and Egyptian Hijri date records.
- **Services:** Finance ledger/store, SMS parser and redactor, Egyptian calendar repository and astronomical estimator, Hawl/Zakat calculators, local notification scheduler, and encrypted backup service.
- **Persistence:** A versioned local Codable JSON snapshot. Financial records remain on device.
- **System integrations:** Apple Shortcuts/App Intents for user-authorized message handoff; UserNotifications for local reminders; document importer/exporter for user-controlled backup.

## Current implementation and verification

- Native SwiftUI app with five primary tabs: Wallet, Accounts & Cards, Activity, Debts, and Savings & Zakat.
- Latest completed full simulator verification: [GitHub Actions run #41275559071](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41275559071), source head `358dfbb3de1e03bc1909cab952b93fa48add51b1`.
- The workflow built the app and test bundles with Xcode 16.4 and passed **144 unit tests plus 16 UI tests, with zero failures**.
- The CI build targets an iPhone simulator with code signing disabled. It does not validate physical-device behavior, signed installation, actual notification delivery, or App Store readiness.
- PR #1 remains open, draft, and unmerged. No merge, release, or production deployment is authorized.

## Persistence and migration contract

- The current implementation stores a Codable `FinanceSnapshot` as JSON at Application Support/`SavingsZakat/finance-data.json`.
- `FinanceSnapshot.currentSchemaVersion` is **1**. The store rejects a snapshot with an unsupported schema version rather than silently decoding or overwriting it.
- Writes use Foundation's atomic file-write option. A missing file loads as an empty snapshot.
- The earlier prototype used `@AppStorage("testHoldingsJSON")`. When no new snapshot exists, the store decodes that key as the legacy `[Holding]` JSON array, writes a version-1 `FinanceSnapshot` atomically, and removes the legacy key only after the write succeeds.
- Malformed legacy JSON is surfaced and retained. If the new snapshot cannot be written, the legacy value is retained. An existing snapshot takes precedence; the store does not merge a leftover legacy key into an existing snapshot.
- Tests cover save/reload, first launch, legacy migration, malformed legacy preservation, failed-migration preservation, corrupt-file preservation, unsupported schema rejection, atomic snapshot replacement, and record create/update/delete persistence.
- A sequential migration pipeline between future schema versions (N → N+1) is **not implemented**. Do not change the schema version until explicit ordered migrations and tests exist.

## Data safety and imported messages

- Store card brand/label and last four digits only. Never store full PAN, CVV, PIN, OTP, bank password, or authentication secret.
- Imported SMS is redacted before persistence. `ImportedMessage` stores only a redacted excerpt, parsed fields, confidence, fingerprint, and a default `needsReview` state; the original message is not retained.
- `SensitiveTextRedactor` removes OTP, CVV, CVC, PIN, password/passcode tokens, and long card-like digit sequences before a source excerpt is retained.
- `BankMessageParser` recognizes a deliberately limited set of English/Arabic transaction keywords and amount/currency formats. It rejects unknown, conflicting, and multi-amount messages rather than guessing.
- The parser's SHA-256 fingerprint is based on normalized redacted message content. The local Shortcut coordinator combines it with normalized sender identity and a five-minute received-time window; identical content alone is not a sufficient real-world deduplication key.
- The app cannot directly read the iPhone SMS inbox. User-configured Apple Shortcuts passes selected message text through the supported App Intent/app handoff. Unattended execution depends on iOS version and user settings; manual share/paste remains the fallback.
- Imported items require explicit user review/confirmation before ledger posting. Unknown formats remain unparsed rather than being assigned a guessed amount or direction.

## Finance ledger and accounting

- `FinanceLedger` operates on a value-copy of `FinanceSnapshot`; successful mutations return the updated snapshot for persistence through `FinanceStore`.
- Only confirmed transactions affect account balances. Imported transactions marked `needsReview` are rejected by ledger posting until confirmed.
- Income and expenses reference an existing source account and match its currency. Transfers reference two different existing accounts in the same currency; cross-currency transfers are rejected until an explicit exchange/fee model exists.
- A transfer is one ledger transaction with a source and destination account. It decreases one account and increases the other by the same amount; it is not income or expense.
- Duplicate transaction IDs and duplicate liability IDs are rejected. Accounts with transaction history or linked cards cannot be deleted.
- Net-worth summaries convert account balances and liabilities to a selected currency using caller-supplied positive rates. Missing rates generate explicit provisional warnings; a missing value is never silently represented as a valid zero.

## Credit-card reconciliation

- Credit-card purchases are expense transactions linked to a credit card, with no bank-account source. They increase the card's outstanding balance and appear in expense reporting, but do not reduce a bank account.
- Credit-card repayments are transfer transactions from a bank/cash account to a credit card. They reduce the paying account and the card balance by the same amount; they are not recorded as expenses.
- Only credit cards can receive purchases or repayments. Card and paying-account currencies must match. Repayments larger than the current outstanding balance are rejected.
- Card tracking is current-state only: one calculated outstanding balance, optional credit limit, minimum payment, statement date, and payment due date. There is no monthly statement archive or statement-by-statement history.
- The ledger calculates outstanding from the opening amount, confirmed purchases (including fees/interest), confirmed repayments, and one current-state reconciliation adjustment. Editing the balance updates that adjustment in place; it does not create a monthly statement archive or general change history.
- When an existing credit-card liability is linked as the opening balance, that liability remains the single opening-balance source and the card editor does not allow a second opening amount.
- Imported bank-message review can confirm a message as an account transaction, a credit-card purchase, or a card repayment. The selected card/account is validated against message currency, and the imported-message ID remains the duplicate-protection key.
- Card records retain only last four digits and optional limit/due details. Cards with linked transactions or opening liabilities cannot be deleted.

## Egyptian calendar and Zakat

- Gregorian dates are the only user-input dates.
- The bundled Egyptian Hijri dataset is version **2026.10.2** and contains **16 Dar Al-Ifta announcement-backed month starts**: 11 records for 1447 AH and five consecutive records for 1448 AH.
- The 1447 AH Shawwal record is intentionally absent because a direct final Dar Al-Ifta announcement was not independently located. The calendar must not infer that missing start or bridge the Ramadan-to-Dhu al-Qi'dah gap as a confirmed interval.
- A date is labelled officially confirmed only when the relevant official month-start boundaries support that interval. The first day of the latest announced month can be confirmed from its announcement; uncovered dates remain Estimated.
- For uncovered dates, the app uses an offline Cairo-reference astronomical estimator based on the Dar Al-Ifta criteria documented in `Documentation/Egyptian-Calendar-Sources.md`: conjunction before sunset, at least 8° solar separation, and at least 10 minutes of moonset lag. If required events cannot be calculated, it falls back to Islamic-civil arithmetic.
- **Both the astronomical estimator and Islamic-civil fallback are always labelled Estimated.** Neither is an official Egyptian month declaration. The estimator uses one Cairo reference point and does not model all Egyptian observation committees, local atmospheric conditions, or an actual sighting.
- Dar Al-Ifta's official announcement records remain the only source for confirmed month starts. Astronomy is supporting estimation only and is never silently promoted to official status.
- Calendar table updates are reviewed/versioned app data; no paid API or mandatory network request is required at runtime.
- Hawl is evaluated per holding against the Egyptian calendar mapping. Eligible matured holdings are combined according to the selected test method.
- Missing exchange rates or metal prices produce explicit provisional results and never block calculation.

## Calendar source policy

- Primary authority: [Egyptian Dar Al-Ifta lunar-month sighting service](https://www.dar-alifta.org/en/service/lunar-months-moon-sighting) and its dated month-start announcements.
- Supporting astronomical reference: [National Research Institute of Astronomy and Geophysics (NRIAG)](https://www.nriag.sci.eg/), including its annual astronomical Hijri guides. These are estimates unless a corresponding Egyptian official announcement confirms the month start.
- Source records, announcement dates, deliberate gaps, calculation criteria, and limitations are documented in [Egyptian-Calendar-Sources.md](Egyptian-Calendar-Sources.md).
- A third-party compilation may help discover announcements, but each date must be checked against an Egyptian official announcement before entering the confirmed table.

## Hawl reminders

- Hawl reminders are local notifications with stable per-asset identifiers: 30 days, 7 days, 1 day, and due date.
- Planned fire time is 9:00 AM for the corresponding Cairo civil date.
- Permission is requested only after the user initiates scheduling/refresh. Denied permission must not be represented as a successful schedule.
- Refresh replaces only this app's `hawl.` notifications. Editing or deleting an asset cancels its old reminders.
- The scheduler caps pending requests at 64 and prioritizes the nearest fire times. Notification schedules are not included in encrypted backups and must be recreated after restore.

## Recurring transactions

- Recurring templates are stored in the local finance snapshot as an optional field so existing schema-version-1 snapshots without that field remain decodable.
- Templates support income and expenses on daily, weekly, monthly, or yearly intervals. Transfers are deliberately excluded because recurring transfer semantics need separate review.
- A user explicitly triggers due-entry creation from Activity. No background or automatic posting occurs.
- Each generated transaction stores its recurring rule ID and occurrence date; the ledger checks that pair to avoid posting the same occurrence twice.
- Due entries affect balances only after the user chooses **Create due entries**. Generation is capped at 120 occurrences per rule per action. The UI supports adding, pausing, resuming, and deleting rules.

## Backup and restore

- Backup is user-initiated and local; no automatic upload or cloud dependency exists.
- The backup envelope uses PBKDF2-HMAC-SHA256 with 600,000 iterations and AES-256-GCM authenticated encryption. The passphrase remains user-held.
- Restore validates the archive and requires explicit replacement confirmation.
- The finance snapshot includes accounts, cards, transactions, liabilities, holdings, and persisted finance preferences. Pending SMS review items and notification schedules are excluded and must be recreated.

## UI direction and validation limits

- Five primary tabs: Wallet, Accounts & Cards, Activity, Debts, and Savings & Zakat. Settings, monthly insights, Hawl calendar, and encrypted backup are reachable from Wallet.
- The Wallet net-worth headline covers account balances and recorded liabilities only; it excludes gold/silver holdings until their valuations are incorporated.
- The selected visual direction is Design 4 composition with Design 3 palette: pale-blue surfaces, royal-blue actions, violet debt accents, and gold asset highlights. The shared surface treatment is applied to all eight List screens and fourteen Form screens. This code-level consistency pass is not a substitute for rendered screenshot or physical-device visual sign-off.
- Quick Add opens existing transaction, account, and holding editors using existing ledger/save paths. The icon has a 44×44-point frame and accessibility label/hint/identifier.
- UI automation includes Quick Add → Account editor and Wallet launch under a dark appearance override. The latter proves launch under the override only; it is not a visual Dark Mode audit.
- No simulator screenshot review or rendered contrast measurement has been recorded. Full VoiceOver, Dynamic Type, touch-target, color-independence, and physical-device accessibility review remain outstanding.
- All 69 entries in `Documentation/Device-Test-Checklist.md` remain unchecked. A signed development build and physical iPhone are required before sign-off.

## Free and offline operation

No subscriptions, paid APIs, paid backend, paid notification provider, mandatory cloud account, or runtime network dependency is required for the core app. Rates and prices are manually entered; encrypted backup is user-controlled and local.


## Visual system and accessibility

- `DESIGN.md` is the canonical visual reference. The approved direction is the Design 4 compact Wallet composition with the Design 3 royal-blue, pale-blue, violet and gold palette.
- `UX-CONTRACT.md` is the canonical navigation, interaction and accessibility contract. Preserve native SwiftUI navigation and form controls; visual refinements must not bypass existing ledger, persistence, calendar or reminder services.
- `FinancePalette` in `SavingsZakat/Views/FinanceTabs.swift` owns the expressive palette, dynamic Light/Dark colors, semantic income/expense/warning/danger colors, and UIKit system surfaces.
- `financeScreenSurface()` is applied to all eight List screens and fourteen Form screens. Primary Lists use inset-grouped sections; screen backgrounds use dynamic UIKit grouped surfaces.
- The Zakat screen uses four accessible asset-entry tiles. Debt balances use violet; gold is reserved for asset/icon accents. Transaction direction is present in row text as well as its icon.
- Monthly charts expose an accessible summary/hint and retain a readable monthly value list beneath the chart.
- Custom toolbar actions have accessible names and 44×44-point minimum frames. Account/card rows and asset tiles expose action hints and stable identifiers.
- `FinancePaletteTests` calculates contrast using resolved UIKit colors in Light and Dark appearances. It enforces at least 4.5:1 for text accents/status colors and 3:1 for gold non-text accents against system, grouped and pale-blue surfaces.
- `Documentation/Accessibility-Visual-Review.md` records the code-level findings, reference contrast calculations, automated coverage, and outstanding device checks.
- **Not yet signed off:** the latest full simulator run passed, but no screenshot review or actual-device contrast measurement has been recorded. VoiceOver, full Dynamic Type, all touch targets, physical Dark Mode, Reduce Motion, and other device accessibility settings remain open.
