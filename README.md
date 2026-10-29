# Savings & Zakat — Native iOS

An isolated native SwiftUI iPhone app workstream for tracking cash, currencies, and gold and testing combined zakat calculations. This repository is separate from the existing PWA: https://github.com/AhmedSaied88/savings-zakat-pwa

## Status

**Prototype source scaffold — not yet verified as a buildable or installable app.** Use fictional test data only. Do not use its outputs as authoritative religious or financial advice.

## Repository layout

- `SavingsZakat/` — SwiftUI app, holding model, and date/calculation services.
- `SavingsZakatTests/` — XCTest coverage for lunar-year dates and combined calculation behavior.
- `Documentation/` — design specification and implementation plan.
- `project.yml` — XcodeGen project definition.
- `.github/workflows/ios-test.yml` — macOS GitHub Actions build/test workflow.

## Build

Requires macOS with Xcode and the iOS Simulator. Install XcodeGen, then run:

```sh
xcodegen generate
xcodebuild test -project SavingsZakat.xcodeproj -scheme SavingsZakat -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Physical-device installation requires an Apple signing team/profile. The unit-test workflow does not produce a signed IPA.

## Boundaries and outstanding work

- Unique app bundle identifier and local-only test records; no synchronization with or changes to the PWA.
- Prices and exchange rates are manual; missing values must be shown as provisional.
- Durable storage, edit flow, silver-entry UI, reminder scheduling, encrypted backup/restore, UI tests, physical iPhone validation, and a verified build remain outstanding.
- Do not replace the PWA or use real financial data until tests pass and the user explicitly approves the next release step.
