# UX Contract

## Product boundary and locale

- Native iPhone SwiftUI app; five primary tabs: Wallet, Accounts, Activity, Debts, and Zakat.
- English UI is the current shipped interface. Bank-message parsing supports selected English and Arabic message patterns; this does not imply a fully localized Arabic UI.
- Gregorian dates are the input format. Egyptian Hijri equivalents are displayed with explicit Confirmed/Estimated provenance.
- Financial records, calculations, imports, reminders and backups remain local. No sign-in, subscription, bank API or required cloud service.

## Navigation ownership

- `ContentView` owns the persistent five-tab `TabView`.
- Each primary tab owns a `NavigationStack` and native `List` or `Form`.
- Wallet links to Monthly Insights and Settings & Backup.
- Settings links to Finance Preferences and Backup & Restore.
- Finance Preferences links to Hawl Calendar & Reminders.
- Create/edit workflows use native sheets with Cancel and Save actions.
- Preserve navigation and return destinations when presenting or dismissing sheets.

## Canonical UI primitives

| Capability | Canonical owner | Allowed pattern | Required behavior |
|---|---|---|---|
| Primary navigation | `ContentView` | Native `TabView` | Five named tabs remain reachable |
| Screen navigation | Each tab's `NavigationStack` | Native navigation | Descriptive title and back navigation |
| Lists | SwiftUI `List` with inset-grouped style | Native rows and sections | Natural scrolling, swipe actions only where offered |
| Forms | SwiftUI `Form` | Native fields, pickers, toggles, date pickers | Scrollable, Dynamic Type friendly, Save/Cancel |
| Add actions | Native toolbar `Menu` or `Button` | Labeled icon or text action | Accessible name/hint; custom icon target at least 44×44 pt |
| Confirm/Cancel | Native toolbar buttons | Save / Cancel | No silent close when validation fails |
| Feedback | Inline status text or system `alert` | Success/error copy near the workflow | State the outcome and next action; never claim a failed save succeeded |
| Charts | Swift Charts plus readable value rows | Chart with text equivalent | Values and currencies remain available without chart interpretation |

## Financial record workflows

- Account/card/transaction/asset/liability edits use the existing ledger and store paths; visual changes must not bypass validation or persistence.
- Imported bank messages begin in Needs Review. Balances change only after the user explicitly confirms.
- Financial record corrections use simple editing without general change history. Existing saved Zakat calculations remain preserved as designed.
- Credit-card purchases increase card debt without reducing bank balance. Repayments reduce both the paying account and card debt and are not a second expense.
- Recurring income/expense templates do not post automatically. The user explicitly chooses Create due entries.
- Destructive actions remain explicit and must respect linked-record deletion constraints.

## Status and data confidence

- Confirmed, Estimated, provisional, missing valuation, warning, enabled/paused and destructive states must have explicit text; color and icons are supplementary.
- Egyptian official month starts are sourced from Dar Al-Ifta announcements. Cairo astronomical and Islamic-civil calculations are estimates only.
- Missing exchange rates or metal prices produce a provisional result; never silently substitute zero or present it as final.
- Card identifiers are masked to last four digits. Never request or retain full card number, CVV, PIN, OTP or bank password.

## Accessibility behavior

- Use native SwiftUI controls and semantic roles wherever possible.
- Every icon-only action has an accessibility label; add a hint when the consequence is not obvious.
- Decorative icons are hidden from assistive technology. Icons that communicate direction or status have an equivalent text label.
- Combine row content into one accessibility element only when the row is one logical action; preserve useful amount, status and due-date information in its label.
- Custom interactive targets are at least 44×44 points. Native platform controls retain their system sizing.
- Text uses Dynamic Type and may wrap; do not truncate essential amounts, dates, warnings or action labels.
- Status is never communicated by color alone.
- Validate Light/Dark appearance, VoiceOver, large text, and actual device behavior before release.

## Offline, errors and recovery

- Local persistence failures are surfaced; never overwrite corrupt or unsupported snapshots silently.
- Failed imports remain reviewable and do not alter balances.
- Notification permission denial is reported without claiming reminders were scheduled.
- Backup restore requires explicit replacement confirmation; failed authentication leaves current records unchanged.
- Pending SMS review items and notification schedules are not included in backup and must be recreated after restore.

## Verification evidence and release gate

- Simulator UI tests and unit tests are the automated regression baseline; CI uses signing-disabled simulator builds.
- Automated dark appearance launch is not a visual contrast audit.
- Physical iPhone install, Shortcuts behavior, local notifications, VoiceOver, Dynamic Type and touch-target review require a signed development build.
- No merge, TestFlight, App Store release or production deployment without explicit user approval.
