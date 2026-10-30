# Savings & Zakat — Native iOS

A separate, native SwiftUI iPhone application for personal-finance tracking and Egyptian-calendar Savings & Zakat calculations. This repository is isolated from the existing PWA: https://github.com/AhmedSaied88/savings-zakat-pwa

## Current status

**Working prototype foundation — not release-ready or verified on a physical iPhone.** The isolated feature branch now includes the versioned local store, validated finance ledger, tab-based Wallet / Accounts / Activity / Debts / Zakat screens, account editing, transaction categories, masked cards, credit-card statement/payment fields, and a Shortcuts-assisted bank-message import queue with explicit transaction confirmation, plus a unified editable asset register for cash, gold, silver and manual investments. Egyptian calendar, Zakat, and SMS parsing features remain subject to their documented verification limits. Use fictional test data only; do not treat outputs as authoritative religious or financial advice.

Latest confirmed full Xcode test run for the ledger work:
- Branch: `chore/task-1-baseline-architecture`
- Commit: `f91e86e287da0da6a0f7acbd4ab7f7abb02872cc`
- Workflow run: [Native iOS build and tests #41020025055](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41020025055)
- Result: **33 XCTest tests passed, 0 failures** on macOS 15 / Xcode 16.4 / iPhone 16 simulator.
- The subsequent tab UI, UI-test target and expanded SMS parser changes are not yet Xcode-verified: recent GitHub Actions jobs failed before a runner was assigned (runner ID 0, no steps executed). The parser/redactor logic separately passed 15 targeted checks in a local Swift 6.2.1 harness.

## Repository layout

- `SavingsZakat/Models/` — holding, account, card, transaction, liability, imported-message and finance snapshot models.
- `SavingsZakat/Services/` — local finance store, finance ledger, Egyptian Hijri calendar, Hawl/Zakat calculations, bank message parser and sensitive-text redactor.
- `SavingsZakat/Views/` — tab-based SwiftUI Wallet, Accounts & Cards, Activity, Debts and Savings & Zakat screens.
- `SavingsZakatTests/` — calculation, calendar, persistence, ledger and bank-message parser tests.
- `SavingsZakatUITests/` — iPhone simulator UI automation for navigation, account/transaction entry and card masking/payment details.
- `Documentation/Architecture.md` — architecture, data safety and migration contract.
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
- Egyptian official month-start records must be verified and bundled before dates can be labelled officially confirmed. Uncovered dates must remain estimated.
- Hawl calculations, Zakat assumptions and all valuation inputs require further verification and transparent presentation.
- UI automation has been added but still needs a successful Xcode run; accessibility, Dynamic Type, Dark Mode and physical-device validation remain outstanding.
- The ledger currently validates income, expense, transfers, duplicate posting and liabilities; recurring transactions, full credit-card payment reconciliation and broader import deduplication remain future work.
- The Shortcuts App Intent, local import/review queue and unified asset register are implemented but not yet Xcode-verified; the Shortcut flow also needs physical-iPhone testing. Egyptian date-source verification, reminders, encrypted backup/restore and release packaging remain incomplete.
- Prices and exchange rates are manual; missing values must be shown as provisional.
- Use fictional test data until physical-device validation and explicit approval for any production-use step.
