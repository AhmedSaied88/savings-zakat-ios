# Savings & Zakat — Native iOS

A separate, native SwiftUI iPhone application for personal-finance tracking and Egyptian-calendar Savings & Zakat calculations. This repository is isolated from the existing PWA: https://github.com/AhmedSaied88/savings-zakat-pwa

## Current status

**Working prototype foundation — not yet release-ready or verified on a physical iPhone.** The current feature branch contains the wallet/account/transaction model, local JSON snapshot persistence, cash/gold/silver entry, combined Zakat calculation, Egyptian Hijri conversion framework, bank-message parsing/redaction, and XCTest coverage. Use fictional test data only; do not treat outputs as authoritative religious or financial advice.

Latest verified GitHub Actions run at the baseline commit:
- Branch: `feature/iphone-personal-finance-native`
- Commit: `6c1b08ef59063892cb1103d07b40b9d10c8a9213`
- Workflow run: [Native iOS build and tests #25](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41017441370)
- Result: **16 tests passed, 0 failures** on the iPhone 16 simulator using Xcode 16.4.

## Repository layout

- `SavingsZakat/Models/` — holding, account, card, transaction, liability and finance snapshot models.
- `SavingsZakat/Services/` — local finance store, Egyptian Hijri calendar, Hawl/Zakat calculations and bank message parser.
- `SavingsZakat/Views/` — SwiftUI wallet and finance-entry screens.
- `SavingsZakatTests/` — calculation, calendar, persistence and bank-message parser tests.
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
- Edit/delete flows, complete ledger accounting, duplicate-import protection, SMS Shortcut handoff, reminders, encrypted backup/restore, UI tests, physical iPhone validation and release packaging remain incomplete.
- Prices and exchange rates are manual; missing values must be shown as provisional.
- Use fictional test data until physical-device validation and explicit approval for any production-use step.
