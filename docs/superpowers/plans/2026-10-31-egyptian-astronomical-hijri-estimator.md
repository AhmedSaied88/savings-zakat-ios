# Egyptian Astronomical Hijri Estimate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Islamic-civil-only fallback for uncovered dates with an offline Egyptian-reference astronomical estimate while preserving official Dar Al-Ifta dates as the only confirmed source.

**Architecture:** Keep the official month-start table and confirmation rules unchanged. Add an isolated estimator that locates recent conjunctions and evaluates the first evening that meets the selected Egyptian visibility criteria using on-device Sun/Moon positions and rise/set calculations. Use Cairo as the reference coordinate and preserve the civil-midnight date convention; all calculated outputs remain Estimated.

**Tech Stack:** Swift 5.9, SwiftUI app target iOS 17+, XCTest, XcodeGen, SunCalc Swift package (MIT, pinned to commit `7e8ad5cbdf2742fb68527612ba6bf78e7f55dfe0`).

**Spec:** `docs/superpowers/specs/2026-10-30-egyptian-savings-zakat-redesign-design.md`

## Global Constraints

- Native SwiftUI app; minimum deployment target iOS 17.0.
- No paid APIs, subscriptions, paid backend, or required cloud account.
- All date conversion and astronomical calculations run locally; no runtime network access.
- Official Egyptian Dar Al-Ifta announcements remain the sole source of .officiallyConfirmed.
- Uncovered and future dates remain .estimated, with method and reference location disclosed.
- Do not use Saudi Umm al-Qura as the production source of truth.
- Preserve the existing civil Gregorian date convention and the 16 source-backed records.
- The existing PWA and its data remain untouched.

## Review Focus

1. A date in an official bounded interval must remain officially confirmed and must bypass the estimator.
2. The latest official month-start day remains confirmed; later days remain estimated until the next official announcement.
3. A missing month record must not create a false confirmed interval.
4. A conjunction after local sunset must not make that same evening a candidate.
5. Missing sunset/moonset events or invalid ephemeris output must fall back safely to the explicitly labelled arithmetic estimate.

---

### Task 1: Pin the astronomy engine and prove the fallback behavior

**Files:**
- Modify: `project.yml` — add pinned SunCalc package to the app target.
- Modify: `SavingsZakatTests/EgyptianHijriCalendarTests.swift`.

**Interfaces:**
- SunCalc product: `SunCalc`.
- The app target imports SunCalc; no network calls are made by app code at runtime.

- [ ] Add `testUncoveredDateUsesEgyptianAstronomicalEstimateAndRemainsEstimated` for 2026-11-15; assert status remains .estimated, day is within 1–30, and the calculation note identifies the Egyptian astronomical method and Cairo reference.
- [ ] Run CI and confirm the new assertion fails against the current Islamic-civil-only fallback for the expected reason.
- [ ] Add SunCalc as a pinned SwiftPM dependency in XcodeGen configuration, using the exact revision above; confirm the app and test targets resolve the package.
- [ ] Commit the failing regression test separately from production implementation.

### Task 2: Implement the Egyptian visibility estimator

**Files:**
- Create: `SavingsZakat/Services/EgyptianAstronomicalEstimator.swift`.
- Modify: `SavingsZakat/Services/EgyptianHijriCalendar.swift`.
- Modify: `SavingsZakatTests/EgyptianHijriCalendarTests.swift`.
- Modify: `Documentation/Egyptian-Calendar-Sources.md`.

**Interfaces:**
- `EgyptianAstronomicalEstimator.estimate(containing:timeZone:)` returns an optional estimate containing month start and method note.
- Default reference coordinates: Cairo, latitude 30.0444° N, longitude 31.2357° E.
- Visibility assessment uses the Dar Al-Ifta page dated 10 December 2011: at least 8° separation from conjunction, the crescent after sunset, and moonset at least 10 minutes after sunset.
- The implementation finds conjunction by detecting the waxing phase wrap in SunCalc, then searches the first three post-conjunction evenings for the first passing Cairo assessment.
- The first civil date after the passing observation evening is the estimated month start.
- Hijri year/month labels use Islamic-civil arithmetic only as a numbering framework, adjusted to the nearest estimated civil month boundary; it is not a confirmation source.

- [ ] Add deterministic tests for the 8° threshold, 10-minute moonset-lag threshold, and conjunction-before-sunset condition.
- [ ] Implement the estimator with finite-value and missing-event guards.
- [ ] Route uncovered-date conversion through the estimator; retain the existing Islamic-civil fallback only when astronomical calculation cannot produce an estimate.
- [ ] Keep official interval resolution ahead of the estimator.
- [ ] Update source documentation with the exact algorithm, Cairo coordinate, source limitations, and explicit note that calculated results are not Dar Al-Ifta announcements.
- [ ] Run all unit and UI tests in GitHub Actions and inspect the test log for counts and failures.
- [ ] Commit implementation and documentation.

## Source and method ruling

The Dar Al-Ifta fatwa dated 10 December 2011 (No. 2345) states that visibility may be possible when the crescent has separated from conjunction by at least 8°, the event occurs after sunset, and the moon remains above the horizon for at least 10 minutes. A separate Dar Al-Ifta page describes a 15h40 threshold. These are distinct published descriptions; this implementation deliberately uses the 8°/10-minute criteria from the 2011 method page and does not combine thresholds from separate texts. Cairo is a single reference point, whereas Dar Al-Ifta describes observation committees at multiple locations across Egypt. The resulting prediction is therefore only a local estimate, never a national official calendar result.

## Completion Criteria

- Official dates and gap behavior are unchanged.
- Uncovered dates use the Egyptian astronomical estimator when its required events are available.
- All computed dates remain explicitly Estimated.
- No runtime network dependency is introduced.
- Unit and UI tests pass in CI.
- The PR remains draft and unmerged; no release is authorized by this plan.
