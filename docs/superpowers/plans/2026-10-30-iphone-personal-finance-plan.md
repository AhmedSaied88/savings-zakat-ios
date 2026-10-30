# iPhone Personal Finance & Savings & Zakat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a free, offline-first native iPhone personal-finance app with account/card/transaction tracking, Shortcuts-assisted bank SMS import, and Egypt-specific Hijri Hawl and combined Zakat tools.

**Architecture:** SwiftUI app with a versioned local persistence layer and domain services separated from views. SMS arrives only through user-configured iOS Shortcuts and a documented app handoff; all parsing, calculations, reminders and financial data remain on device. Egyptian calendar conversion uses a versioned source-backed date table plus clearly labelled estimates where official Egyptian dates are not yet available.

**Tech Stack:** SwiftUI, Foundation, XCTest, UserNotifications, App Intents / URL handoff, Apple Shortcuts, GitHub Actions on macOS.

**Spec:** `docs/superpowers/specs/2026-10-30-egyptian-savings-zakat-redesign-design.md`

## Global Constraints
- iPhone only; native SwiftUI and iOS navigation.
- No subscriptions, paid APIs, paid backend, paid notification provider, or required cloud account.
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
- [ ] Inspect all source files, project configuration, current branch and latest CI workflow.
- [ ] Add baseline tests for current calculation and persistence behavior before refactoring.
- [ ] Document model/service boundaries and migration strategy.
- [ ] Run the complete existing XCTest workflow and record baseline result.

### Task 2: Versioned local store
**Files:** Create `SavingsZakat/Services/FinanceStore.swift`, `SavingsZakat/Models/FinanceSnapshot.swift`, `SavingsZakatTests/FinanceStoreTests.swift`.
**Interfaces:** `FinanceStore.load() throws -> FinanceSnapshot`; `FinanceStore.save(_ snapshot: FinanceSnapshot) throws`; `FinanceSnapshot.schemaVersion: Int`.
- [ ] Test first launch, save/reload, migration, corrupt-file recovery and atomic writes.
- [ ] Implement versioned local persistence and safe migration from prototype holdings JSON.
- [ ] Verify create/update/delete survive app relaunch in tests.

### Task 3: Accounts, cards, liabilities and ledger
**Files:** Create `Account.swift`, `PaymentCard.swift`, `Transaction.swift`, `Liability.swift`, `FinanceLedger.swift` and `FinanceLedgerTests.swift` under Models/Services/Tests.
**Interfaces:** `FinanceLedger.netWorth(in:rates:) -> MoneySummary`; `FinanceLedger.post(_ transaction: Transaction) throws`; `FinanceLedger.transfer(amount:from:to:date:) throws`. Card display stores last four digits only.
- [ ] Test balance changes, income/expense, paired transfers, credit-card liability, loans/instalments and currency conversion.
- [ ] Implement ledger validation and duplicate transaction protection.
- [ ] Test account deletion constraints and transfer accounting.

### Task 4: Wallet and account/card UI
**Files:** Refactor `ContentView.swift`; create Wallet, Accounts, Cards, Transactions and Liabilities SwiftUI views under `SavingsZakat/Views/`.
- [ ] Add UI tests for account CRUD, card masking, credit-card due dates and transaction categories.
- [ ] Implement Design 4 composition with Design 3 blue palette: white/pale-blue surfaces, royal-blue actions, violet accents and gold asset highlights.
- [ ] Build Wallet, Accounts & Cards, Transactions, Add Account and Debts sections with native navigation/sheets.
- [ ] Verify accessibility labels, Dynamic Type, Dark Mode and 44pt touch targets.

## Workstream B — Bank SMS via Shortcuts

### Task 5: SMS parser and privacy layer
**Files:** Create `BankSMSParser.swift`, `SensitiveTextRedactor.swift`, `ImportedMessage.swift` and `BankSMSParserTests.swift`.
**Interfaces:** `BankSMSParser.parse(_ text: String, receivedAt: Date) -> ParsedBankMessage`; `SensitiveTextRedactor.redact(_ text: String) -> String`; parsed messages carry confidence.
- [ ] Add fixture tests for fictional Egyptian bank debit, credit, ATM, POS, transfer, fee, reversal and card-payment messages.
- [ ] Test duplicate fingerprints and OTP/PIN/CVV/credential redaction.
- [ ] Implement confidence-aware parsing with safe unparsed fallback.
- [ ] Require confirmation before posting imported transactions.

### Task 6: Shortcuts handoff
**Files:** Create `ImportBankMessageIntent.swift`, `MessageImportCoordinator.swift`, `Documentation/Apple-Shortcuts-SMS-Setup.md` and coordinator tests.
- [ ] Test payload validation, duplicate delivery, redaction and fallback.
- [ ] Implement App Intent or supported URL handoff after verifying deployment-target compatibility.
- [ ] Document Message automation by sender/keywords and passing message text into the app.
- [ ] Document iOS automation permission/unattended-execution variability and share/paste fallback.
- [ ] Never claim unrestricted SMS inbox access or universal silent delivery.

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
