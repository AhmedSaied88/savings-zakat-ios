# Implementation Plan — Native iOS Test Build

1. Add failing XCTest coverage first for date reminder lead times, completed hawl at the correct Umm al-Qura anniversary, combined eligible assets, missing rate warnings, asset persistence, and edit/delete.
2. Extend holding model with stable record metadata and date validation; keep Codable backward compatibility.
3. Add versioned local repository with atomic persistence and test-only storage.
4. Build tabbed SwiftUI UI: Overview, Assets, Prices, Reminders. Add cash/currency, gold, silver sheets; edit flows; a unified asset list.
5. Add per-holding next anniversary and countdown. Schedule local notifications at 30/7/1/0 days, cancel/reschedule on edits/deletes, expose notification permission status.
6. Harden combined calculator and provisional warnings, with a calculation breakdown.
7. Add UI tests and CI artifact upload for simulator .app (not signed IPA).
8. Run macOS Xcode CI and inspect logs; provide a test build artifact and instructions. Do not claim installable on device without signing.