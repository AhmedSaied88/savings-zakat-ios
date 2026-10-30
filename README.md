# Savings & Zakat — Native iOS

A separate, native SwiftUI iPhone application for personal-finance tracking and Egyptian-calendar Savings & Zakat calculations. This repository is isolated from the existing PWA: https://github.com/AhmedSaied88/savings-zakat-pwa

## Current status

**Working prototype foundation — not release-ready or verified on a physical iPhone.** This isolated SwiftUI application includes a versioned local store and validated ledger; five primary tabs (Wallet, Accounts, Activity, Debts and Zakat); Shortcuts-assisted bank-message import with redaction, custom parser rules and explicit transaction confirmation; an editable cash/gold/silver/investment register; a Hawl calendar with local reminders; combined Zakat calculations with per-asset breakdown; encrypted local backup/restore; persisted valuation/parser preferences; and monthly income/expense insights.

The latest previously verified full GitHub Actions simulator run passed on macOS 15 / Xcode 16.4. Recurring transactions and credit-card reconciliation were added after that run and still require a fresh CI run:
- Branch: `chore/task-1-baseline-architecture`
- Commit: `c677f05a9a531573e1fb25c0573cb7a738874857`
- Workflow run: [Native iOS build and tests #238](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41073908869)
- Result: **119 unit tests and 10 UI tests passed; 0 failures.** This run predates the latest credit-card reconciliation implementation and its additional UI test.
- Simulator: iPhone simulator selected by the workflow. This is CI evidence, not physical-device validation.

Egyptian calendar data currently bundles five Dar Al-Ifta month starts from 1448 AH (June–October 2026). Dates outside the bounded official coverage use an explicitly estimated Islamic-civil fallback, not an Egypt-specific astronomical calculation. Use fictional test data only; do not treat outputs as authoritative religious or financial advice.

## Repository layout

- `SavingsZakat/Models/` — holding, account, card, transaction, liability, imported-message and finance snapshot models.
- `SavingsZakat/Services/` — local finance store, finance ledger, Egyptian Hijri calendar, Hawl/Zakat calculations, bank message parser and sensitive-text redactor.
- `SavingsZakat/Views/` — tab-based SwiftUI Wallet, Accounts & Cards, Activity, Debts and Savings & Zakat screens, plus Hawl, insights, settings and encrypted backup views.
- `SavingsZakatTests/` — calculation, calendar, persistence, ledger, import, notification, backup, preferences and insights tests.
- `SavingsZakatUITests/` — iPhone simulator UI automation for navigation, account/transaction entry and card masking/payment details.
- `Documentation/Architecture.md` — architecture, data safety and migration contract.
- `Documentation/Device-Test-Checklist.md` — physical-iPhone validation steps for Shortcuts, reminders, backup, offline behavior and accessibility.
- `docs/superpowers/specs/` — approved product/design requirements.
- `docs/superpowers/plans/` — phased implementation plan.
- `project.yml` — XcodeGen project definition.
- `.github/workflows/ios-test.yml` — macOS GitHub Actions build/test workflow.

## Build and test

Requires macOS with Xcode and the iOS Simulator. Install XcodeGen, then run:

```sh
xcodegen generate
xcodebuild test -project "Savings Zakat.xcodeproj" -scheme SavingsZakat -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Physical-device installation requires an Apple signing team/profile. The simulator unit-test workflow does not produce a signed IPA.

## Persistence and data migration

- Current local storage is a versioned Codable JSON snapshot at Application Support/`SavingsZakat/finance-data.json`.
- Schema version 1 is supported. Unsupported schema versions are rejected; a sequential migration pipeline is not yet implemented.
- The earlier `@AppStorage("testHoldingsJSON")` prototype format is imported on first load when no finance snapshot exists. The legacy key is removed only after the new snapshot is written successfully.
- Malformed legacy data and failed writes are surfaced without deleting the legacy value. Existing snapshots are not merged with legacy data.
- Persistence tests cover save/reload, first launch, migration, malformed/corrupt data preservation, unsupported schema rejection, repeated atomic snapshot replacement and record create/update/delete persistence.
- Sequential schema-version migrations remain outstanding; schema version 1 is the only supported format.

## Boundaries and outstanding work

- This native iOS repository, its local data and its test deployment are separate from the PWA; do not replace, modify or migrate the PWA.
- The initial Egyptian date seed contains five verified Dar Al-Ifta month starts (1448 AH, June–October 2026); broad historical coverage and an Egypt-calibrated astronomical estimate remain outstanding. Dates outside the bounded official intervals must remain estimated.
- Hawl calculations, Zakat assumptions and all valuation inputs require further verification and transparent presentation.
- Twelve UI automation tests are currently defined, covering navigation, account/card entry, settings, parser rules, backup, large Dynamic Type, recurring entries and credit-card reconciliation. The latest verified run executed 10 UI tests before the two newest UI scenarios were added; a fresh run is still required. Full accessibility, Dynamic Type, Dark Mode and physical-device review remain outstanding.
- The ledger validates income, expenses, transfers, duplicate posting and liabilities. Recurring income/expense templates support manual due-entry generation. Credit-card purchases and repayments now reconcile separately: purchases increase card debt without debiting a bank account, while repayments debit the paying account and reduce card debt without being counted as another expense. Existing manually recorded card liabilities can be linked to a card as its opening balance to prevent double counting. Full import deduplication remains future work.
- The Shortcuts App Intent, local import/review queue, unified asset register, initial Egyptian official-date seed, Hawl reminders, encrypted backup/restore, preferences and insights are implemented but not yet Xcode-verified. The Shortcut, notifications and backup/restore flows also need physical-iPhone testing. Broad historical Egyptian date coverage, an Egypt-calibrated astronomical estimate and release packaging remain incomplete.
- Prices and exchange rates are manual; missing values must be shown as provisional.
- Use fictional test data until physical-device validation and explicit approval for any production-use step.
