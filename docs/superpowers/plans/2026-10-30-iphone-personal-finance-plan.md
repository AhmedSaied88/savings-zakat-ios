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

**Task 6 implementation note (2026-10-30):** Added a local import coordinator and atomic JSON queue in Application Support, a Shortcuts App Intent with open-app behavior, and an Activity review queue. Raw SMS text is redacted before persistence; unknown formats are retained with no guessed amount/direction; duplicate checks combine normalized sender, redacted fingerprint and a five-minute time window. The review screen requires the user to verify the transaction type and select an account; transfers require a distinct destination account. Only the explicit confirmation action posts a confirmed transaction through FinanceLedger. Ignoring an import does not post it. Eleven coordinator XCTest cases are present, including concurrent repeated-delivery coverage. The latest GitHub Actions run is still queued / the previous runs have failed before runner assignment (runner ID 0, no steps), so Task 6 is implemented but **not Xcode-verified**; do not mark it complete until the macOS/Xcode test workflow passes and the physical-iPhone Shortcut flow is validated.

## Workstream C — Assets, Egyptian Calendar and Zakat

### Task 7: Unified assets
**Files:** Modify `Holding.swift`; create unified asset list, silver-entry and holding-editor views; add asset-management tests.
- [ ] Test cash, currencies, gold, silver and manual investments plus edit/delete.
- [ ] Implement unified list with value, dates, category, Hawl countdown and provisional pricing state.
- [ ] Keep Gregorian date pickers for acquisition and Hawl start.

### Task 8: Egypt-specific Hijri engine
**Files:** Create `EgyptianHijriCalendar.swift`, `EgyptianMonthStart.swift`, `EgyptianCalendarRepository.swift`, tests and `Documentation/Egyptian-Calendar-Sources.md`.
**Interfaces:** `EgyptianHijriCalendar.convert(gregorianDate: Date) -> EgyptianHijriDate`; each result has confirmed/estimated status and provenance.
- [ ] Verify trustworthy Egyptian official month-start records and document provenance before labelling dates confirmed.
- [ ] Test known published Egyptian dates, month transitions, leap years, time zones, future unannounced dates and manual overrides.
- [ ] Implement a bundled versioned local date table and documented Egypt-calibrated estimates for uncovered dates.
- [ ] Display Hijri date immediately after Gregorian selection, with Confirmed/Estimated status.
- [ ] Do not use Umm al-Qura as Egypt's source of truth; no network requirement for conversion.

### Task 9: Hawl and Zakat engine
**Files:** Modify `HawlCalculator.swift`, `ZakatCalculator.swift`; add Egyptian Hawl and calculation tests.
- [ ] Test one-lunar-year anniversary per holding against Egyptian date mapping and status.
- [ ] Test combined eligible wealth, Nisab boundary, 2.5%, personal-use gold setting, missing rates/prices and date boundaries.
- [ ] Replace Umm al-Qura dependency with Egyptian calendar service.
- [ ] Ensure missing prices/rates never block calculation; show provisional warnings and included/excluded breakdown.

### Task 10: Hawl calendar and reminders
**Files:** Create `HawlNotificationScheduler.swift`, `HawlCalendarView.swift` and scheduler tests.
- [ ] Test 30/7/1-day and due-date schedules, denied permission, rescheduling, cancellation, time-zone changes and date corrections.
- [ ] Implement local notifications with stable IDs and no remote service.
- [ ] Show upcoming Hawl in Gregorian and Hijri dates with confidence status.

## Workstream D — Backup, Settings and Release

### Task 11: Backup and restore
**Files:** Create `BackupService.swift` and tests.
- [ ] Test export/import round-trip, invalid archive, schema mismatch and encrypted archive authentication.
- [ ] Implement user-controlled local export/import with encryption and user-held passphrase.
- [ ] Never upload financial records automatically.

### Task 12: Settings, insights and UI tests
**Files:** Create Settings and Insights views plus `SavingsZakatUITests/FinanceAppUITests.swift`.
- [ ] Test manual exchange rates/prices, parser rules, calendar status, privacy and reminders.
- [ ] Add monthly income/expense summaries from confirmed ledger transactions.
- [ ] Add UI tests for primary flows and large Dynamic Type.

### Task 13: Final verification and iPhone testing
**Files:** Modify `README.md` and `.github/workflows/ios-test.yml`; create `Documentation/Device-Test-Checklist.md`.
- [ ] Run complete macOS/Xcode build and XCTest/UI test workflow.
- [ ] Verify no paid dependencies or services are required.
- [ ] Verify existing PWA repository/deployment/data are untouched.
- [ ] Test Shortcuts handoff on a physical iPhone and document iOS version/settings/limitations.
- [ ] Test local notifications, offline calculation, backup/restore, Dark Mode and accessibility on device.
- [ ] Report remaining gaps; do not claim App Store-ready or production-ready without evidence and explicit release approval.
