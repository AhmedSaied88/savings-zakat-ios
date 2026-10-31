# SwiftUI CI Compile Errors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the confirmed SwiftUI compile errors in the Wallet, Zakat, and Hawl Calendar views, then establish reliable free CI verification for the native iOS app.

**Architecture:** Keep SwiftUI `Section` declarations inside their owning `List` builder so SwiftUI can infer the correct List section types. Move complex row/content compositions into focused `View` components or `@ViewBuilder` content properties, and isolate bindings and formatting from large view-builder expressions. Keep CI compilation separate from simulator test execution so an unavailable simulator runtime is not misreported as an application compile failure.

**Tech Stack:** Swift 5, SwiftUI, XCTest, XCUITest, XcodeGen, GitHub Actions, macOS 15 / Xcode 16.4.

**Spec:** `docs/superpowers/specs/2026-10-30-egyptian-savings-zakat-redesign-design.md`; preserve the existing product decisions in `docs/superpowers/plans/2026-10-30-iphone-personal-finance-plan.md`.

## Global Constraints

- iPhone only; native SwiftUI and iOS navigation.
- No subscriptions, paid APIs, paid backend, or required cloud account.
- Financial data, SMS parsing, calculations, date conversion and reminders run locally.
- Existing PWA, its production deployment and its data remain untouched.
- Never store full card numbers, CVV, PIN, OTP, banking passwords or authentication secrets.
- Imported SMS transactions require review/confirmation by default.
- Use fictional test data until physical-device validation and explicit approval.
- Do not merge or release the draft pull request until Xcode compilation, automated tests, and required device checks are verified.
- Keep CI on GitHub's standard free macOS runner for this public repository; do not enable paid runner types or raise spending limits.
- Do not download simulator runtimes blindly; inspect the runner's available Xcode destinations first.

## Review Focus

1. Empty and populated account lists must both render in the Wallet without ambiguous SwiftUI Section overloads.
2. Empty and populated Hawl calendars must render with the section headers and rows intact.
3. Zakat preferences, result breakdown, warnings, and price inputs must remain reactive after view decomposition.
4. Reminder scheduling must handle permission denied, scheduled, partially scheduled, and limited results without a missing switch case.
5. CI must distinguish a successful generic iOS simulator build from actual simulator test execution; no green test claim when tests did not run.

---

### Task 1: Restore List section builder context

**Files:**
- Modify: `SavingsZakat/Views/FinanceTabs.swift` — `WalletDashboardTab.body`, Accounts section.
- Modify: `SavingsZakat/Views/HawlCalendarView.swift` — `body` and upcoming/reminder sections.
- Test: `SavingsZakatUITests/FinanceAppUITests.swift`.

**Interfaces:**
- Keep each `Section` declaration lexically inside its owning `List { ... }`.
- Any extracted helper must return row/content views, not a `Section` value.

- [ ] Add UI coverage for Wallet with no accounts and with an account, and for opening the Hawl calendar with no eligible holdings.
- [ ] Reproduce the existing compiler errors on the CI branch before changing the implementation.
- [ ] In `WalletDashboardTab`, make the Accounts section use an unambiguous List content builder. If needed, extract account rows into a dedicated `View` or `@ViewBuilder` content property; do not extract the `Section` itself.
- [ ] In `HawlCalendarView`, move the three `Section` declarations back into `List`; extract only the section contents into focused views/properties.
- [ ] Preserve the existing labels, reminder actions, date ordering, empty states, and accessibility behavior.
- [ ] Run the UI test target build and confirm the Section generic-inference errors are gone.

### Task 2: Decompose the combined Zakat calculation view

**Files:**
- Modify: `SavingsZakat/Views/FinanceTabs.swift` — `AssetsZakatTab` and the combined Zakat calculation section.
- Test: `SavingsZakatUITests/FinanceAppUITests.swift`.

**Interfaces:**
- Preserve `AssetsZakatTab(snapshot:onSave:preferences:)`.
- Preserve the existing `ZakatCalculator` and `ZakatResult` domain behavior; this task is view decomposition only.
- Keep the `Combined Zakat calculation` Section declaration inside the parent `List`.

- [ ] Add UI assertions for Nisab input, personal-use-gold toggle, Calculate Zakat action, and result visibility with fictional data.
- [ ] Extract the Nisab input and personal-use-gold toggle into small focused view components or explicitly typed bindings.
- [ ] Extract result totals, per-holding breakdown rows, and provisional warnings into focused child views.
- [ ] Keep calculation invocation and `.onChange` recalculation behavior in `AssetsZakatTab`.
- [ ] Keep manual exchange-rate, gold-price, and silver-price editing behavior unchanged.
- [ ] Run the UI test target build and confirm the expression type-check timeout is gone.

### Task 3: Verify notification result handling and Hawl presentation

**Files:**
- Modify: `SavingsZakat/Views/HawlCalendarView.swift`.
- Test: `SavingsZakatTests/HawlNotificationSchedulerTests.swift` and `SavingsZakatUITests/FinanceAppUITests.swift`.

**Interfaces:**
- Handle all current `HawlNotificationScheduler.ScheduleResult` cases: `.permissionDenied`, `.scheduled(count:)`, `.partiallyScheduled(count:failedIdentifiers:)`, and `.limited(count:omittedCount:)`.
- Do not change the planner's four reminder offsets, Cairo civil-date rules, or 64-pending-notification cap.

- [ ] Verify scheduler tests cover the limited result and notification cap.
- [ ] Keep the exhaustive result switch and user-facing explanation for omitted reminders.
- [ ] Add/retain a UI test proving the Hawl calendar displays without scheduling notifications or requesting permission.
- [ ] Run the scheduler unit tests and Hawl calendar UI test.

### Task 4: Make CI diagnostics deterministic and separate build from simulator execution

**Files:**
- Modify: `.github/workflows/ios-test.yml`.
- Optionally modify: `Documentation/Architecture.md` and `README.md` to describe verified CI levels accurately.

**Interfaces:**
- Generic build command: `xcodebuild build-for-testing -project "$PROJECT" -scheme SavingsZakat -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`.
- Simulator tests may be reported as passed only when `xcodebuild test` actually runs and exits successfully on an available simulator destination.

- [ ] Retain generic `build-for-testing` as the compile gate and capture Xcode version plus available simulator destinations in the job log.
- [ ] Remove the unconditional `xcodebuild -downloadPlatform iOS` step; run `xcrun simctl list devices available` as a diagnostic without making a missing simulator look like a Swift compile error.
- [ ] Add a separate simulator-test step/job that selects a destination from the runner's actual available devices; if no simulator runtime/device is available, mark simulator execution as unavailable/skipped with an explicit notice rather than claiming tests passed.
- [ ] Keep the workflow on `macos-15` standard hosted runners and avoid paid runner sizes.
- [ ] Verify the generic build gate on the current feature branch. Then verify simulator tests independently on a runner with an available iOS runtime.
- [ ] Update documentation with the exact distinction between compile verification and executed XCTest/XCUITest results.

---

## Completion Criteria

- No Swift compiler errors in `FinanceTabs.swift` or `HawlCalendarView.swift`.
- All current scheduler result cases are handled exhaustively.
- Generic iOS simulator build-for-testing succeeds.
- Unit and UI tests are reported as passed only after actual execution.
- Existing product behavior and the PWA remain unchanged.
- Draft PR #1 remains unmerged pending final review and iPhone 13 Pro Max / iOS 27.0.1 device checks.
