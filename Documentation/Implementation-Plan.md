# Implementation Plan

1. Generate the Xcode project from `project.yml` on macOS.
2. Run XCTest on an iOS simulator and fix all build/test failures.
3. Add a versioned durable local store and test create/edit/delete behavior.
4. Add silver entry and editing for all asset types in the unified list.
5. Implement local notifications with stable IDs and rescheduling/cancellation on edits and deletion.
6. Add UI tests for input validation, persistence, and calculation results.
7. Implement encrypted backup/restore and verify recovery.
8. Validate lunar anniversary boundaries, time zones, rates, nisab comparisons, and combined eligible wealth.
9. Install on a physical iPhone with Apple signing and verify reminders.
10. Obtain explicit user approval before any PWA replacement.

Use fictional test data only. Never claim the app is installable until a macOS/Xcode workflow has passed. Do not change the existing PWA or its production deployment.
