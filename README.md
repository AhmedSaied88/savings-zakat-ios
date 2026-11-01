# Savings & Zakat — Native iOS

A separate, native SwiftUI iPhone application for personal-finance tracking and Egyptian-calendar Savings & Zakat calculations. This repository is isolated from the existing PWA: https://github.com/AhmedSaied88/savings-zakat-pwa

## Current status — 2026-11-01

**Core implementation and current simulator regression suite pass. The app is not release-ready and has not been validated on a physical iPhone.**

Latest completed GitHub Actions pull-request run: [run #41332224997](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41332224997), testing PR head `e220135304e9fe05381501ff7266f0c57be4c9c0`:
- App and test bundles built successfully with Xcode 16.4.
- **144 unit tests and 17 UI tests passed; zero failures.**
- The latest accessibility-size navigation test and all four individually reachable Zakat asset-entry actions pass.
- A dedicated UI test captured the Wallet, Accounts, Activity, Debts and Zakat tabs. All five PNG attachments and a manifest were exported successfully.
- [XCTest diagnostics and screenshot artifact](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41332224997/artifacts/13094012224) (available for 7 days from 2026-11-01).
- CI runs on an iPhone simulator with code signing disabled. It is not evidence of physical-device behavior or a signed distribution build.
- [XCTest diagnostics artifact](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41277309339/artifacts/13072131631).

Pull request [#1](https://github.com/AhmedSaied88/savings-zakat-ios/pull/1) remains **open and draft**. It is not merged and is not approved for merge or release. No changes have been made to the existing PWA.

## Implemented capabilities

- Five primary SwiftUI tabs: Wallet, Accounts & Cards, Activity, Debts, and Savings & Zakat.
- Local versioned Codable JSON persistence, atomic writes, legacy prototype holdings migration, and ledger validation.
- Accounts, cards, transactions, paired own-account transfers, liabilities, and credit-card purchase/repayment reconciliation.
- Credit-card opening balances and linking an existing card liability as the single opening-balance source.
- Bank-message import through a user-configured Apple Shortcuts handoff; Arabic/English parsing, sensitive-text redaction, duplicate protection, and explicit review before posting.
- Cash, gold, silver, and manual-investment asset register; Hawl and Zakat calculations with per-asset breakdown.
- Egyptian Hijri date provenance, 16 bundled Dar Al-Ifta month-start records across 1447–1448 AH, and an offline Cairo-reference astronomical estimator for uncovered dates. Calculated dates remain **Estimated**, never official.
- Local Hawl reminders, encrypted user-controlled backup/restore, valuation/parser preferences, monthly insights, and manual-confirmed recurring income/expense templates.
- App-wide visual consistency pass: native inset-grouped lists, shared dynamic surfaces for all List/Form screens, semantic high-contrast status colors, violet debt accents, gold asset highlights, accessible asset-entry tiles, and accessible chart summaries.

## Important limitations and remaining work

- **Physical iPhone validation:** all 69 items in `Documentation/Device-Test-Checklist.md` remain unchecked. A signed development build and physical iPhone are required.
- **Visual/accessibility sign-off:** code-level refinements and runtime contrast tests are in place, and simulator tests pass, and the five-tab simulator screenshots are now available for review, but visual sign-off and physical-device review are not recorded. VoiceOver, full Dynamic Type across all screens, every custom touch target, actual iPhone Dark Mode, and Reduce Motion remain outstanding. The dark-appearance UI test verifies launch under an appearance override only.
- **Signing and release:** CI uses simulator builds with code signing disabled. No signed IPA, TestFlight build, App Store release, or production deployment has been created.
- **Schema evolution:** schema version 1 is the only supported snapshot format. A sequential N → N+1 migration pipeline must be implemented and tested before a future schema-version bump.
- **Egyptian calendar coverage:** the 16 official source-backed starts are a partial dataset, not a complete historical calendar. Shawwal 1447 is intentionally absent because a direct final Dar Al-Ifta announcement was not independently verified. The implementation does not bridge that gap as a confirmed interval.
- **Valuation:** exchange rates and metal prices are entered manually. Missing values produce provisional results rather than blocking calculations.
- **SMS:** iOS does not provide unrestricted inbox access to this app. User-configured Shortcuts is the bridge; trigger/unattended behavior depends on iOS settings, and manual share/paste remains the fallback.
- **Credit cards:** balances are current-state reconciliation, not monthly statement archives.
- **Recurring entries:** income and expense templates generate due entries only after the user explicitly requests them. No automatic/background posting or recurring transfers.
- **Backup scope:** pending SMS review items and notification schedules are not included in the encrypted finance snapshot and must be recreated after restore.

Use fictional test data only until physical-device validation and explicit approval for any production-use step. Do not treat calculated outputs as authoritative religious or financial advice.

## Repository layout

- `SavingsZakat/Models/` — holding, account, card, transaction, liability, imported-message, preference, and finance snapshot models.
- `SavingsZakat/Services/` — local finance store, ledger, parser/redactor, Egyptian calendar and estimator, Hawl/Zakat calculations, reminders, and backup.
- `SavingsZakat/Views/` — Wallet, Accounts & Cards, Activity, Debts, Savings & Zakat, Hawl, insights, settings, and backup screens.
- `DESIGN.md` — canonical native visual system and palette.
- `UX-CONTRACT.md` — navigation, interaction and accessibility contract.
- `Documentation/Accessibility-Visual-Review.md` — code-level review, contrast policy and remaining device checks.
- `SavingsZakatTests/` — unit tests for calculations, calendar, persistence, ledger, imports, reminders, backup, preferences, insights, and palette contrast.
- `SavingsZakatUITests/` — simulator UI automation.
- `Documentation/Architecture.md` — architecture, data safety, calendar provenance, and migration contract.
- `Documentation/Device-Test-Checklist.md` — physical-iPhone validation checklist.
- `Documentation/Egyptian-Calendar-Sources.md` — official source records and estimate methodology.
- `docs/superpowers/specs/` — approved product/design requirements.
- `docs/superpowers/plans/` — phased implementation plan and historical execution notes.
- `project.yml` — XcodeGen project definition.
- `.github/workflows/ios-test.yml` — macOS GitHub Actions build/test workflow.

## Build and test

Requires macOS with Xcode and XcodeGen:

```sh
xcodegen generate
xcodebuild test -project "Savings Zakat.xcodeproj" -scheme SavingsZakat -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

The CI workflow uses simulator signing-disabled builds. Installing on a physical iPhone requires an Apple signing team/profile and a separate device validation pass.

## Persistence and migration contract

- The app stores a Codable `FinanceSnapshot` JSON file at Application Support/`SavingsZakat/finance-data.json`.
- Current schema version: **1**. Unsupported schema versions are rejected rather than silently decoded or overwritten.
- The earlier `@AppStorage("testHoldingsJSON")` prototype format is imported only when no current snapshot exists. The legacy key is removed only after the new snapshot has been written successfully.
- Failed writes, malformed legacy data, corrupt snapshots, and unsupported versions must not silently erase existing financial records.
- Sequential future schema migrations are not implemented. Add explicit ordered migrations and tests before increasing the schema version.

## Safety and privacy boundaries

- Store card brand/label and last four digits only. Never store full PAN, CVV, PIN, OTP, bank password, or authentication secret.
- Redact sensitive text before imported message excerpts are persisted. Imported messages start in `needsReview`; only explicit user confirmation posts a ledger transaction.
- Financial data and calculations remain local. Backup is user-initiated, encrypted, and not automatically uploaded.
- The app has no required backend, subscription, paid API, or cloud account.
