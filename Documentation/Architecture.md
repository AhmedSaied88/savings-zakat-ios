# Architecture

## App boundary
This is a separate iPhone-only SwiftUI application. It does not share storage, authentication, deployment, or data with the existing Savings & Zakat PWA.

## Layers
- **Presentation:** SwiftUI tab screens and entry forms. Views submit validated operations to the finance ledger and persist the returned snapshot; they do not calculate transaction balances themselves.
- **Domain models:** Accounts, payment cards, transactions, liabilities, holdings, money values and Egyptian Hijri date records.
- **Services:** Finance ledger, SMS parser/redactor, Egyptian calendar repository, Hawl/Zakat calculators, local notification scheduler and backup service.
- **Persistence:** Versioned local snapshot/database. All financial records remain on device.
- **System integrations:** Apple Shortcuts/App Intents for user-authorized SMS message handoff; UserNotifications for local reminders; file importer/exporter for backup.

## Current persistence implementation and migration contract
- The current implementation stores a Codable `FinanceSnapshot` as JSON at Application Support/`SavingsZakat/finance-data.json`.
- `FinanceSnapshot.currentSchemaVersion` is currently `1`. The store rejects a snapshot with an unsupported schema version rather than silently decoding or overwriting it.
- Writes use Foundation's atomic file-write option. A missing file currently loads as an empty snapshot.
- The current store has no sequential schema migration pipeline yet. Future schema changes must add explicit, ordered migrations (N → N+1), preserve IDs and financial values, and write the migrated snapshot atomically only after successful decoding and validation.
- A failed decode, failed validation, or unsupported future version must not replace the original file. Recovery must be explicit and must never silently reset financial records.
- The earlier prototype used `@AppStorage("testHoldingsJSON")`. When no new snapshot file exists, the store now decodes that key as the legacy `[Holding]` JSON array, writes a version-1 `FinanceSnapshot` atomically, and removes the legacy key only after the write succeeds.
- Malformed legacy JSON is surfaced as a decoding error and retained in `UserDefaults`. If the new snapshot cannot be written, the legacy value is also retained. An existing snapshot takes precedence; the store does not merge a leftover legacy key into an existing snapshot.
- Current persistence tests cover save/reload, first launch, legacy migration, malformed legacy preservation, failed-migration preservation, corrupt-file preservation, unsupported schema rejection, atomic snapshot replacement, and record create/update/delete persistence.
- Sequential migrations between future schema versions (N → N+1) remain unimplemented. Do not change the schema version until an explicit migration path and tests are added.

## Data safety
- Store only card brand/label and last four digits. Never store full PAN, CVV, PIN, OTP, bank password or authentication secret.
- Imported SMS is redacted before persistence. `ImportedMessage` stores only the redacted excerpt, parsed fields, confidence, fingerprint and a default `needsReview` state; the original message is not retained.
- `SensitiveTextRedactor` removes OTP, CVV, CVC, PIN, password/passcode tokens and long card-like digit sequences before any source excerpt is retained.
- `BankMessageParser` recognizes a deliberately limited set of English/Arabic transaction keywords and amount/currency formats. It rejects unknown, conflicting and multi-amount messages rather than guessing.
- The parser's SHA-256 fingerprint is based on normalized redacted message content. The local Shortcut coordinator combines it with normalized sender identity and a five-minute received-time window; identical content alone is not a sufficient real-world deduplication key.
- A transfer is one ledger transaction with a source and destination account. It decreases one account and increases the other by the same amount; it is never counted as income or expense.
- Local backup is user-initiated and encrypted. No automatic upload or cloud dependency.

## Calendar and Zakat
- Gregorian dates are the only user input dates.
- Egyptian Hijri conversion uses a versioned, bundled seed of five month starts confirmed by Egypt's Dar al-Ifta announcements. Dar al-Ifta describes its nationwide religious/scientific crescent-sighting committees as the authority for all lunar months. NRIAG astronomical calendars may be consulted as estimates/reference material, not silently promoted to official sightings.
- Dates outside verified official coverage use Foundation's Islamic-civil arithmetic fallback, clearly labelled as an estimate; this is not an Egypt-specific astronomical prediction. Do not extrapolate an official status from a forecast. Record the source URL, announcement date, Hijri month/year, and Gregorian start date for every official table entry.
- Calendar table updates are reviewed/versioned app data; no paid API or mandatory network request is required at runtime.
- Every displayed Hijri date includes provenance status: Officially confirmed or Estimated.
- Hawl is evaluated per holding against the Egyptian calendar mapping; eligible matured holdings are combined according to the selected test method.
- Missing rates/prices produce explicit provisional results and never block the calculation.

## Egyptian calendar source policy
- Primary authority: [Egyptian Dar al-Ifta lunar-month sighting service](https://www.dar-alifta.org/en/service/lunar-months-moon-sighting) and its dated month-start announcements.
- Supporting astronomical reference: [National Research Institute of Astronomy and Geophysics (NRIAG)](https://www.nriag.sci.eg/), including its annual astronomical Hijri guides. These are estimates unless a corresponding Egyptian official announcement confirms the month start.
- A third-party compilation may help discover announcements, but each date must be checked against an Egyptian official announcement before entering the confirmed table.

## Recurring transactions
- Recurring templates are stored in the local finance snapshot as an optional field so existing schema-version-1 snapshots without that field remain decodable.
- Templates support income and expenses on daily, weekly, monthly or yearly intervals. Transfers are deliberately excluded because recurring transfer semantics need a separate review.
- A user explicitly triggers due-entry creation from Activity. No background or automatic posting occurs. Each generated transaction stores its recurring rule ID and occurrence date; the ledger checks that pair to avoid posting the same occurrence twice.
- Due entries are confirmed ledger transactions and affect balances only after the user chooses Create due entries. Generation is capped at 120 occurrences per rule per action to bound catch-up work. The UI supports adding, pausing, resuming and deleting rules.

## Credit-card reconciliation
- Credit-card purchases are expense transactions linked to a credit card, with no bank-account source. They increase the card's outstanding balance and appear in expense reporting, but do not reduce a bank account.
- Credit-card repayments are transfer transactions from a bank/cash account to a credit card. They reduce the paying account and the card balance by the same amount; they are not recorded as expenses.
- Only credit cards can receive purchases or repayments. Card and paying-account currencies must match. Repayments larger than the current outstanding balance are rejected; fees, interest and overpayments must be entered separately or addressed in a later workflow.
- Imported bank-message review can confirm a message as an account transaction, a credit-card purchase or a card repayment. The selected card/account is validated against the message currency, and the imported-message ID remains the duplicate-protection key.
- A credit card can carry an opening outstanding balance. An existing manually recorded credit-card liability can be linked to the card and is then treated as its opening balance, not added a second time. Standalone liabilities remain separate. Existing liabilities should be linked when they represent a card already tracked in Accounts.
- Card records retain only last four digits and optional limit/due details; no full PAN, CVV, PIN or OTP is stored. Cards with linked transactions or opening liabilities cannot be deleted.

## Finance ledger
- `FinanceLedger` operates on a value-copy of `FinanceSnapshot`; successful mutations return the updated snapshot for the caller to persist through `FinanceStore`.
- Only confirmed transactions affect account balances. Imported transactions marked `needsReview` are rejected by ledger posting until confirmed.
- Income and expenses must reference an existing source account and match its currency. Transfers must reference two different existing accounts in the same currency; cross-currency transfers are rejected until an explicit exchange/fee model exists.
- Duplicate transaction IDs and duplicate liability IDs are rejected. Accounts with transaction history or linked cards cannot be deleted.
- Net-worth summaries convert account balances and liabilities to the selected currency using caller-supplied positive rates. Missing rates generate explicit provisional warnings; no missing value is silently represented as a valid zero.
- Card records contain only last four digits plus optional currency, opening outstanding balance, credit limit, statement date, payment due date and minimum due. Card purchases and repayments are linked through optional transaction card IDs; all added fields are optional for backward-compatible decoding. Transaction category is optional for older snapshots and newly entered transactions can assign a category.

## UI direction
The five primary SwiftUI tabs provide Wallet, Accounts & Cards, Activity, Debts and Savings & Zakat. Settings, monthly insights, the Hawl calendar and encrypted backup are reachable from Wallet. The Wallet net-worth headline currently covers account balances and recorded liabilities only; it explicitly excludes gold/silver holdings until their valuations are incorporated. The current suite defines 129 unit-test methods and 12 UI tests. The latest previously verified simulator workflow passed 119 unit tests and 10 UI tests on macOS 15 / Xcode 16.4 (run #238, commit `c677f05`). This run predates the credit-card reconciliation changes and their new UI coverage; the current branch requires a fresh run. This verifies automated simulator behavior only; full physical-device, VoiceOver, Dynamic Type and Dark Mode review remains outstanding.

## Free operation
No subscriptions, paid APIs, paid backend, paid notification provider or mandatory cloud account. Manual rates/prices and user-controlled local backup are available offline.

## Platform limitation
The app cannot directly read the iPhone SMS inbox. The user configures Apple Shortcuts Message automations to pass selected message text through a supported App Intent or URL handoff. Trigger availability and unattended execution depend on iOS version and user settings; manual share/paste remains the fallback.
