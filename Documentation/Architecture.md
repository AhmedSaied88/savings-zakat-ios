# Architecture

## App boundary
This is a separate iPhone-only SwiftUI application. It does not share storage, authentication, deployment, or data with the existing Savings & Zakat PWA.

## Layers
- **Presentation:** SwiftUI screens and forms; no financial business rules embedded in views.
- **Domain models:** Accounts, payment cards, transactions, liabilities, holdings, money values and Egyptian Hijri date records.
- **Services:** Finance ledger, SMS parser/redactor, Egyptian calendar repository, Hawl/Zakat calculators, local notification scheduler and backup service.
- **Persistence:** Versioned local snapshot/database. All financial records remain on device.
- **System integrations:** Apple Shortcuts/App Intents for user-authorized SMS message handoff; UserNotifications for local reminders; file importer/exporter for backup.

## Data safety
- Store only card brand/label and last four digits. Never store full PAN, CVV, PIN, OTP, bank password or authentication secret.
- Imported SMS is redacted before persistence. Parsed transactions remain pending until the user confirms them.
- Deduplicate repeated Shortcut deliveries using a stable fingerprint of redacted message content, sender and received timestamp window.
- Account transfers are paired ledger entries, not income/expense.
- Local backup is user-initiated and encrypted. No automatic upload or cloud dependency.

## Calendar and Zakat
- Gregorian dates are the only user input dates.
- Egyptian Hijri conversion uses a versioned, bundled table of verified Egyptian official month starts. Dates outside verified coverage use a documented Egypt-calibrated estimate.
- Every displayed Hijri date includes provenance status: Officially confirmed or Estimated.
- Hawl is evaluated per holding against the Egyptian calendar mapping; eligible matured holdings are combined according to the selected test method.
- Missing rates/prices produce explicit provisional results and never block the calculation.

## UI direction
Use Design 4's layout/composition with Design 3's blue palette: white and pale-blue surfaces, royal-blue primary actions, restrained violet accents and gold asset accents. Prioritize a compact wallet overview, unified transaction list, clear account/card tiles and a simple Add Account flow.

## Free operation
No subscriptions, paid APIs, paid backend, paid notification provider or mandatory cloud account. Manual rates/prices and user-controlled local backup are available offline.

## Platform limitation
The app cannot directly read the iPhone SMS inbox. The user configures Apple Shortcuts Message automations to pass selected message text through a supported App Intent or URL handoff. Trigger availability and unattended execution depend on iOS version and user settings; manual share/paste remains the fallback.
