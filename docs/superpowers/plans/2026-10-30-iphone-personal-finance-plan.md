# iPhone Personal Finance & Savings & Zakat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a free, offline-first native iPhone personal-finance app with account/card/transaction tracking, Shortcuts-assisted bank SMS import, and Egypt-specific Hijri Hawl and combined Zakat tools.

**Architecture:** SwiftUI app with a versioned local persistence layer and domain services separated from views. SMS arrives only through user-configured iOS Shortcuts and a documented app handoff; all parsing, calculations, reminders and financial data remain locally. Egyptian calendar conversion uses a versioned source-backed date table plus clearly labelled estimates where official Egyptian dates are not yet available.

**Tech Stack:** SwiftUI, Foundation, XCTest, UserNotifications, App Intents / URL handoff, Apple Shortcuts, GitHub Actions on macOS.

**Spec:** `docs/superpowers/specs/2026-10-30-egyptian-savings-zakat-redesign-design.md`

## Global Constraints
- iPhone only; native SwiftUI and iOS navigation.
- No subscriptions, paid APIs, paid backend, or required cloud account.
- Financial data, SMS parsing, calculations, date conversion and reminders run locally.
- Existing PWA, its production deployment and its data remain untouched.
- SMS inbox access is not direct: user-configured Shortcuts is the bridge; manual share/paste is the fallback.
- Never store full card numbers, CVV, PIN, OTP, banking passwords or authentication secrets.
- Imported SMS transactions require review/confirmation by default.
- Gregorian is the only date-entry format; display Egypt-specific Hijri equivalent with Officially confirmed or Estimated status.
- Never label astronomical estimates as official Egyptian dates.
- Missing exchange rates or metal prices must not block calculation; results must be marked provisional.
- Use fictional test data until physical-device validation and explicit approval.

## Review Focus
1. Duplicate bank SMS or repeated Shortcut delivery must not create duplicate transactions — test deterministic deduplication.
2. Transfers between the user's own accounts must not inflate income/expenses or net worth — test paired transfer accounting.
3. SMS containing OTPs, PINs, CVVs or ambiguous amounts must be safely redacted/rejected — test secret scrubbing and parse confidence.
4. Egyptian month boundaries and future unannounced starts must never be presented as falsely confirmed — test provenance and date boundaries.
5. Missing rates, invalid values and notification permission denial must not crash or silently misstate totals — test validation and degraded behavior.

---

## Workstream A — Foundation and Wallet

### Task 1: Baseline and architecture
**Files:** Modify `README.md`; create `Documentation/Architecture.md`; test existing calculation suite.
- [x] Inspect all source files, project configuration, current branch and latest CI workflow.
- [x] Add baseline tests for current calculation and persistence behavior before refactoring.
- [x] Document model/service boundaries and migration strategy.
- [x] Run the complete existing XCTest workflow and record baseline result.

**Baseline evidence (2026-10-30):** Branch `feature/iphone-personal-finance-native`, commit `6c1b08ef59063892cb1103d07b40b9d10c8a9213`; GitHub Actions run `41017441370` completed successfully on macOS 15 / Xcode 16.4 / iPhone 16 simulator. XCTest: 16 tests, 0 failures. This is the pre-change baseline; Task 1 documentation updates do not alter executable source.

### Task 2: Versioned local store
**Files:** Existing `SavingsZakat/Services/FinanceStore.swift`, `SavingsZakat/Models/FinanceModels.swift` (`FinanceSnapshot`), and `SavingsZakatTests/FinanceStoreTests.swift`.
**Interfaces:** `FinanceStore.load() throws -> FinanceSnapshot`; `FinanceStore.save(_ snapshot: FinanceSnapshot) throws`; `FinanceSnapshot.schemaVersion: Int`.
- [x] Test first launch, save/reload, legacy migration, corrupt-file recovery, unsupported schema rejection and atomic snapshot replacement.
- [x] Implement versioned local persistence and safe migration from prototype holdings JSON.
- [x] Verify create/update/delete changes survive save/reload in tests.
- [x] Run the complete macOS/Xcode GitHub Actions build and XCTest workflow on the final branch head.

**Task 2 verification (2026-10-30):** Final branch head `02c364d455793d5c6372fdb5e382bf991de664e2`; GitHub Actions run `41019006776` passed on macOS with Xcode and iPhone simulator. XCTest: 23 tests, 0 failures (4 bank parser, 5 Egyptian Hijri calendar, 10 FinanceStore, 2 Hawl, 2 Zakat). The separate Swift 6.2 local persistence harness also passed 10/10. Legacy `testHoldingsJSON` is imported only when no snapshot exists; the new snapshot is written atomically and the old key is removed only after a successful write. Malformed legacy JSON and failed writes preserve the legacy value; corrupt snapshots and unsupported schema versions are not overwritten. Sequential future schema migrations remain unimplemented and must be added before a later schema bump.

### Task 3: Accounts, cards, liabilities and ledger
**Files:** Inspect existing `FinanceModels.swift` first; extend/create account, payment card, transaction, liability and ledger types only where absent. Add `FinanceLedgerTests.swift` under `SavingsZakatTests/`.
**Interfaces:** `FinanceLedger.netWorth(in:rates:) -> MoneySummary`; `FinanceLedger.post(_ transaction: Transaction) throws`; `FinanceLedger.transfer(amount:from:to:date:) throws`. Card display stores last four digits only.
- [x] Test balance changes, income/expense, paired transfers, credit-card liability, loans/instalments and currency conversion.
- [x] Implement ledger validation and duplicate transaction protection.
- [x] Test account deletion constraints and transfer accounting.

**Task 3 verification (2026-10-30):** Added `FinanceLedger.swift` and 10 `FinanceLedgerTests`. GitHub Actions run `41020025055` passed on the native iOS branch with 33 XCTest tests and 0 failures. Tests cover income/expense balances, paired own-account transfers without inflating combined assets, card/loan/instalment liabilities, currency conversion and missing-rate warnings, review gating, duplicate transaction rejection, invalid values, currency mismatch and account deletion constraints. The ledger is a value type over `FinanceSnapshot`; callers persist its updated snapshot through `FinanceStore` after successful operations.

### Task 4: Wallet and account/card UI
**Files:** Refactor `ContentView.swift`; create `SavingsZakat/Views/FinanceTabs.swift`; extend `FinanceEntrySheets.swift`.
- [x] Add UI tests for account creation, card masking, credit-card due-date display and transaction categories.
- [x] Implement the tab-based native navigation structure for Wallet, Accounts & Cards, Transactions, Debts and Savings & Zakat.
- [x] Build account editing, masked card entry, credit-card statement/payment details, transaction categories and validated ledger-backed posting.
- [ ] Refine Design 4 composition with Design 3 blue palette: white/pale-blue surfaces, royal-blue actions, violet accents and gold asset highlights.
- [ ] Verify accessibility labels, Dynamic Type, Dark Mode and 44pt touch targets.

**Task 4 implementation note:** The first UI pass is on the isolated feature branch. The wallet summary uses ledger-computed account balances and liabilities, and explicitly excludes unvalued gold/silver holdings. Account deletion is blocked when cards or transactions are linked; account currency is locked once transactions exist. Transaction creation is routed through `FinanceLedger.post`, including same-currency transfer validation. Credit-card records support optional limit, statement date, payment due date and minimum due. Three UI automation tests have been added. The current GitHub Actions jobs failed before runner assignment (runner ID 0 and no executed steps), so this is an infrastructure/runner verification gap rather than a confirmed code-test result. Re-run the full workflow when a macOS runner is available; do not mark Task 4 complete until it passes.

## Workstream B — Bank SMS via Shortcuts

### Task 5: SMS parser and privacy layer
**Files:** Create `BankSMSParser.swift`, `SensitiveTextRedactor.swift`, `ImportedMessage.swift` and `BankSMSParserTests.swift`.
**Interfaces:** `BankSMSParser.parse(_ text: String, receivedAt: Date) -> ParsedBankMessage`; `SensitiveTextRedactor.redact(_ text: String) -> String`; parsed messages carry confidence.
- [x] Add fixture tests for English/Arabic debit, credit, ATM, POS, transfer, fee, reversal and card-payment messages.
- [x] Test duplicate fingerprints and OTP/PIN/CVV/password/card-number redaction.
- [x] Implement confidence-aware parsing with safe unparsed fallback; ambiguous and multi-amount messages remain unparsed.
- [x] Require confirmation before posting imported transactions through a default `needsReview` imported-message state.

**Task 5 implementation note:** Expanded `BankMessageParser`, extracted `SensitiveTextRedactor`, and added a Codable `ImportedMessage` model. The parser recognizes common English/Arabic transaction types, currency-before/after-amount formats, Arabic-Indic digits and EGP labels. It assigns a confidence level, computes a stable SHA-256 fingerprint from redacted normalized text, and rejects ambiguous or multi-amount messages. Only redacted source text is retained; imported records start in `needsReview`. Sender/time-window deduplication and Shortcut handoff belong to Task 6. A local Swift 6.2.1 parser/redactor harness passed 15 targeted checks, including categories, Arabic currency/digits, duplicate fingerprints, redaction and imported-message serialization. The complete XCTest suite is still awaiting a successful macOS/Xcode run because recent GitHub Actions jobs fail before runner assignment (runner ID 0, no steps executed).

### Task 6: Shortcuts handoff
**Files:** Create `ImportBankMessageIntent.swift`, `MessageImportCoordinator.swift`, `Documentation/Apple-Shortcuts-SMS-Setup.md` and coordinator tests.
- [x] Add coordinator tests for payload validation, duplicate delivery, redaction, unparsed fallback and persistence (Xcode execution pending).
- [x] Implement an iOS 17+ App Intent and App Shortcut action; deployment target is iOS 17.0.
- [x] Document Message automation setup and passing message text into the app.
- [x] Document automation permission/unattended-execution variability and manual fallback.
- [x] Preserve the boundary: no unrestricted SMS inbox access or promise of universal silent delivery.

**Task 6 implementation note (2026-10-30):** Added a local import coordinator and atomic JSON queue in Application Support, a Shortcuts App Intent with open-app behavior, and an Activity review queue. Raw SMS text is redacted before persistence; unknown formats are retained with no guessed amount/direction; duplicate checks combine normalized sender, redacted fingerprint and a five-minute time window. The review screen requires the user to verify the transaction type and select an account; transfers require a distinct destination account. Finance transactions retain the originating imported-message ID, and the ledger rejects a second post from that same import. The finance snapshot is saved before the import queue is marked confirmed; a retry can reconcile an already-posted transaction instead of posting it again. Ignoring an import does not post it. Twelve coordinator XCTest cases are present, including concurrent repeated-delivery coverage. The latest GitHub Actions run failed before runner assignment (runner ID 0, no steps), so Task 6 is implemented but **not Xcode-verified**; do not mark it complete until the macOS/Xcode test workflow passes and the physical-iPhone Shortcut flow is validated.

## Workstream C — Assets, Egyptian Calendar and Zakat

### Task 7: Unified assets
**Files:** Modify `Holding.swift`; create `AssetLedger.swift`, unified asset list/editor and asset-management tests.
- [x] Add tests for cash, currencies, gold, silver and manual investments plus edit/delete (Xcode execution pending).
- [x] Implement a unified list with estimated value, acquisition/Hawl dates, countdown, category and missing-price state.
- [x] Keep Gregorian date pickers for acquisition and Hawl start.

**Task 7 implementation note (2026-10-30):** Added a validated `AssetLedger` for create/update/delete, positive finite values, supported currencies, date ordering, gold carat, silver purity and named manual investments. Expanded `Holding` with backward-compatible optional name/purity fields and added investment valuation plus purity-adjusted silver valuation to Zakat calculation. The Savings & Zakat screen now uses one editable asset register for cash, gold, silver and manual investments; it shows estimated EGP valuation when inputs exist, Gregorian acquisition/Hawl dates, Hawl countdown and a visible valuation-needed state. Ten asset-ledger tests and two persistence/backward-compatibility tests are authored; Xcode execution remains pending due the GitHub runner allocation failure.

### Task 8: Egypt-specific Hijri engine
**Files:** Create `EgyptianHijriCalendar.swift`, `EgyptianMonthStart.swift`, `EgyptianCalendarRepository.swift`, tests and `Documentation/Egyptian-Calendar-Sources.md`.
**Interfaces:** `EgyptianHijriCalendar.convert(gregorianDate: Date) -> EgyptianHijriDate`; each result has confirmed/estimated status and provenance.
- [x] Verify the official Egyptian authority/method and document five consecutive source-backed month starts (1448 AH, June–October 2026).
- [x] Add tests for published month starts, month boundaries, coverage edges, source provenance and future/uncovered estimated status (Xcode execution pending).
- [ ] Expand the bundled versioned table to broad historical coverage and implement a documented Egypt-calibrated astronomical estimate for uncovered dates.
- [x] Display Hijri equivalent immediately beside Gregorian acquisition/Hawl date pickers, with Confirmed/Estimated wording.
- [x] Keep Saudi Umm al-Qura out of the production source of truth; conversion remains offline.

**Task 8 implementation note (2026-10-30):** Dar Al-Ifta's published guidance describes nationwide Egyptian crescent-sighting committees and says the new month is established by sighting; astronomical calculations are supporting evidence, not independent religious confirmation. Added a versioned local seed of five official 1448 AH starts (Muharram through Jumada al-Awwal) with source URLs and announcement dates. A date is confirmed only inside a fully bounded official interval; the latest announcement confirms only its first day until the next month is announced. Uncovered dates use Foundation's Islamic-civil arithmetic fallback, explicitly labelled as an estimate and **not** represented as an Egypt-specific astronomical prediction. UI date pickers show Hijri equivalents immediately. Official-date source coverage is intentionally limited; historical expansion and an Egypt-calibrated astronomical fallback remain open. Calendar tests are authored but not Xcode-verified due runner allocation failures.

### Task 9: Hawl and Zakat engine
**Files:** Modify `HawlCalculator.swift`, `ZakatCalculator.swift`; add Egyptian Hawl and calculation tests.
- [x] Add tests for one-lunar-year anniversaries using Egyptian month mappings and estimated fallback (Xcode execution pending).
- [x] Add tests for combined eligible wealth, inclusive Nisab boundary, 2.5%, personal-use gold, missing rates/prices, invalid inputs and Cairo day boundaries (Xcode execution pending).
- [x] Route Hawl calculations through the Egyptian calendar service; remove Umm al-Qura from the production path and tests.
- [x] Keep missing rates/prices non-blocking and expose provisional warnings plus per-asset included/excluded breakdown.

**Task 9 implementation note (2026-10-30):** Reworked `HawlCalculator` to use `EgyptianHijriCalendar.anniversary` and return Confirmed/Estimated status; completion checks use Cairo civil-day boundaries. Expanded Zakat calculation to validate amounts and metal attributes, value manual investments and purity-adjusted silver, retain total valued assets separately from matured eligible wealth, show personal-use gold as a separately valued exclusion unless the user enables it, apply the inclusive Nisab threshold and 2.5%, and return a per-holding breakdown for included, waiting, excluded, missing-valuation and invalid assets. Added 13 calculation tests for the key arithmetic and boundary cases. Tests are authored but not Xcode-verified because GitHub Actions jobs continue to fail before runner assignment.

### Task 10: Hawl calendar and reminders
**Files:** Create `HawlNotificationScheduler.swift`, `HawlCalendarView.swift` and scheduler tests.
- [x] Add tests for 30/7/1-day and due-date schedules, denied permission, rescheduling, cancellation, time-zone changes and date corrections (Xcode execution pending).
- [x] Implement local notifications with stable IDs, permission handling and no remote service.
- [x] Show upcoming Hawl in Gregorian and Hijri dates with confidence status.

**Task 10 implementation note (2026-10-30):** Added a pure reminder planner and an injected local-notification adapter. It creates stable per-asset reminders at 30, 7 and 1 day before, plus on the due date, at 9:00 AM local time for the Cairo civil date. Permission is requested only after the user taps Schedule/refresh; denied permission leaves the existing schedule intact. Refresh replaces this app's pending Hawl reminders, editing/deleting an asset cancels its old reminders, and cancellation is scoped to the `hawl.` identifier prefix. The Hawl calendar view displays Gregorian/Hijri dates and confidence, and provides schedule/refresh/cancel controls. The scheduler caps pending requests at 64 and prioritizes the nearest fire times. Nine scheduler tests are authored; Xcode execution is pending due runner allocation failures.

## Workstream D — Backup, Settings and Release

### Task 11: Backup and restore
**Files:** Create `BackupService.swift`, backup settings UI and tests.
- [x] Add tests for encrypted round-trip, malformed archive, unsupported version/schema, authentication failure, unsafe KDF parameters and tampering (Xcode execution pending).
- [x] Implement user-controlled local export/import with PBKDF2-HMAC-SHA256, AES-256-GCM and user-held passphrase.
- [x] Never upload financial records automatically; export uses the iOS document picker and restore requires explicit replacement confirmation.

**Task 11 implementation note (2026-10-30):** Added a versioned encrypted backup envelope, 210,000-iteration PBKDF2-HMAC-SHA256 key derivation with random salt, AES-256-GCM authenticated encryption, archive/KDF/schema validation and atomic local file writing. Added a Settings entry from Wallet with export, import and explicit replace confirmation. The encrypted FinanceSnapshot includes accounts, cards, transactions, liabilities, holdings and persisted finance preferences (rates, metal prices, Nisab and parser rules); pending SMS review items and notification schedules are excluded. Nine backup tests are authored; Xcode execution is pending due runner allocation failures.

### Task 12: Settings, insights and UI tests
**Files:** Create Settings and Insights views, preferences model and UI tests.
- [x] Add tests for preference persistence, custom parser rules, monthly summaries and settings/backup navigation (Xcode execution pending).
- [x] Implement persisted exchange rates, metal prices, Nisab/personal-gold settings, editable parser rules, calendar coverage status, privacy notes and reminder navigation.
- [x] Implement monthly summaries from confirmed income/expense transactions only; exclude transfers and pending imports and keep currencies separate.
- [ ] Complete accessibility, Dynamic Type and Dark Mode review; run all unit/UI tests on Xcode.

**Task 12 implementation note (2026-10-30):** Added optional, backward-compatible `FinancePreferences` to the local finance snapshot. Rates, metal prices, Nisab, personal-use gold setting and custom parser rules now persist and are included in encrypted backups. Custom bank rules are passed into the Shortcuts import parser; one match is medium-confidence and multiple matches are rejected for manual review. Added monthly income/expense summaries and charts grouped by currency, using confirmed transactions only (no transfers or pending imports). Settings are reachable from Wallet without adding a sixth tab; the screen includes parser rules, calendar data coverage, privacy notes, Hawl reminders and backup/restore. Added unit and UI tests including accessibility text-size navigation; none have been Xcode-verified yet.

### Task 13: Final verification and iPhone testing
**Files:** Update `README.md` and `.github/workflows/ios-test.yml`; create `Documentation/Device-Test-Checklist.md`.
- [ ] Run complete macOS/Xcode build and XCTest/UI test workflow; recent jobs fail before runner assignment (runner ID 0, no steps).
- [x] Inspect project configuration: only Apple platform frameworks are used; no paid APIs, subscriptions, backend or package dependencies are required.
- [x] Keep the native implementation isolated to `savings-zakat-ios`; no PWA repository, deployment or data actions were taken.
- [ ] Test Shortcuts handoff on a physical iPhone and record iOS version/settings/limitations.
- [ ] Test local notifications, offline calculation, backup/restore, Dark Mode and accessibility on device.
- [x] Add `Documentation/Device-Test-Checklist.md`; do not claim App Store-ready or production-ready without evidence and explicit release approval.

**Task 13 status:** Blocked on two external gates: a working macOS/Xcode GitHub Actions runner, and access to the user's physical iPhone for Shortcuts, notification permission, signing/install, Dark Mode and accessibility validation. No merge or release is authorized.
