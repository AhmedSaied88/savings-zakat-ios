# Implementation Plan

**Status updated:** 2026-11-01  
**Current branch:** `chore/task-1-baseline-architecture`  
**Current PR:** [#1](https://github.com/AhmedSaied88/savings-zakat-ios/pull/1) — open, draft, unmerged.

## Completed implementation and simulator gates

1. [x] Generate the Xcode project from `project.yml` on macOS through GitHub Actions.
2. [x] Run XCTest on an iOS simulator and resolve the known build/test failures.
3. [x] Add a versioned durable local store and test create/edit/delete behavior, legacy import, corrupt data, and failed-write preservation.
4. [x] Add silver entry and editing for all asset types in the unified asset workflow.
5. [x] Implement local notifications with stable IDs and rescheduling/cancellation on edits and deletion; cover partial scheduling failure and the 64-request limit.
6. [x] Add UI tests for input validation, navigation, persistence-related flows, and calculation results.
7. [x] Implement encrypted backup/restore and automated recovery/validation tests.
8. [x] Add automated coverage for lunar anniversary boundaries, time-zone handling, rates, Nisab comparisons, and combined eligible wealth. Manual valuation inputs remain a source of provisional results.

Latest completed simulator verification: [GitHub Actions run #41275559071](https://github.com/AhmedSaied88/savings-zakat-ios/actions/runs/41275559071), source head `358dfbb3de1e03bc1909cab952b93fa48add51b1`. Xcode 16.4 build passed; 144 unit tests and 16 UI tests passed with zero failures. Code signing was disabled.

## Remaining validation and release gates

9. [ ] Install a signed development build on a physical iPhone and complete `Documentation/Device-Test-Checklist.md`, including Shortcuts behavior, notification delivery, backup/restore, offline use, VoiceOver, Dynamic Type, actual Dark Mode, touch targets, and Reduce Motion. Use fictional financial data only.
10. [ ] Obtain explicit user approval before any merge, release, PWA replacement, or production deployment. The existing PWA must remain untouched unless separately authorized.

## Additional engineering limitation

- The local snapshot format is currently schema version 1. A sequential N → N+1 migration pipeline is not implemented. Do not increment the schema version until ordered migrations and regression tests are added.

Use fictional test data only. CI simulator success does not establish physical-device installability, signed-build readiness, or production readiness. Do not change the existing PWA or its production deployment.
