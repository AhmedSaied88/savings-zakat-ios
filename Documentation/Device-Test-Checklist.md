# Physical iPhone validation checklist

> Use fictional financial data and fictional bank-message fixtures only. Never share a real bank SMS, OTP, PIN, CVV, password, full card number or backup passphrase in screenshots or issue reports.

## Test record

- Device model:
- iOS version:
- App build / commit:
- Test date:
- Notification permission state:
- Locale and device time zone:

## 1. Install and local persistence

- [ ] Install the signed development build on an iPhone.
- [ ] Launch offline with Wi-Fi and cellular data disabled.
- [ ] Create a fictional EGP account and a USD account.
- [ ] Close and relaunch the app; confirm both accounts and balances persist.
- [ ] Add a fictional transaction, close/relaunch, and confirm it persists.
- [ ] Confirm no sign-in, subscription, bank API or cloud account is required.

## 2. Bank message Shortcuts handoff

- [ ] Create a user-owned Shortcuts Message automation using a fictional test sender/message.
- [ ] Pass the message body and sender identifier to **Import Bank Message**.
- [ ] Record whether iOS runs the automation unattended or asks for confirmation.
- [ ] Confirm the app opens and the import appears in Activity as **Needs review**.
- [ ] Confirm amount, currency, direction and category are plausible; do not assume parser output is correct.
- [ ] Confirm OTP/PIN/CVV/password/card-like values are redacted in the displayed excerpt.
- [ ] Confirm an unrecognized message is retained for manual review without a guessed amount/direction.
- [ ] Deliver the same fixture again within five minutes; confirm no second queue item is created.
- [ ] Confirm no balance changes until **Review & confirm** is explicitly used.
- [ ] Confirm an own-account transfer requires a distinct same-currency destination account.
- [ ] Confirm an external bank transfer is entered as an expense/income, not as an own-account transfer.

## 3. Hawl reminders

- [ ] Enable local notification permission when prompted from **Hawl calendar**.
- [ ] Schedule reminders for a fictional asset with a future Hawl date.
- [ ] Confirm the 30-day, 7-day, 1-day and due-day notifications appear in iOS pending notifications.
- [ ] Confirm fire times are 9:00 AM local time on the matching Cairo civil date.
- [ ] Change device time zone and tap **Schedule / refresh reminders**; confirm the schedule is rebuilt.
- [ ] Correct the asset Hawl date; confirm its stale reminders are cancelled and refresh creates the corrected schedule.
- [ ] Delete an asset; confirm its pending reminders are cancelled.
- [ ] Deny notifications and confirm the app reports the denial without claiming reminders were scheduled.
- [ ] Confirm estimated Hawl dates remain labelled Estimated in the app.
- [ ] If more than 64 reminders are planned, confirm the app reports the omitted count.

## 4. Zakat and offline valuation

- [ ] Enter fictional cash, gold, silver and manual-investment holdings.
- [ ] Enter fictional exchange rates, gold/silver prices and Nisab.
- [ ] Confirm all manual settings persist after relaunch.
- [ ] Confirm missing rates/prices produce a provisional warning rather than a silent zero.
- [ ] Confirm different currencies are not added together in insights without conversion.
- [ ] Confirm personal-use gold exclusion is clearly shown and the setting changes the eligible total.
- [ ] Confirm only completed-Hawl eligible assets enter the Zakat base.
- [ ] Confirm the displayed per-asset breakdown explains included, waiting, excluded, missing and invalid items.
- [ ] Confirm the app continues to calculate while offline.

## 5. Encrypted backup and restore

- [ ] Export a backup using a new passphrase of at least 12 characters.
- [ ] Save the file to Files; confirm the app does not upload it.
- [ ] Open the exported file in a text viewer; confirm account names and transaction descriptions are not readable plaintext.
- [ ] Restore using the wrong passphrase; confirm authentication fails and current records remain unchanged.
- [ ] Restore using the correct passphrase; confirm the replacement warning appears.
- [ ] Cancel once; confirm current records remain unchanged.
- [ ] Confirm replacement; verify accounts, cards, transactions, liabilities, holdings and persisted preferences restore.
- [ ] Confirm pending bank-message review items and notification schedules are not included and must be recreated.
- [ ] Keep the passphrase separate from the backup file; do not send it to support or ChatGPT.

## 6. Accessibility and appearance

- [ ] Test Light Mode and Dark Mode on device.
- [ ] Test the largest practical Dynamic Type setting.
- [ ] Verify tab/navigation labels and form fields are understandable with VoiceOver.
- [ ] Verify controls remain reachable and do not overlap at large text sizes.
- [ ] Verify touch targets are comfortably tappable (target at least 44 × 44 points).
- [ ] Verify color is not the only way Confirmed/Estimated/Warning states are communicated.
- [ ] Verify charts have meaningful accessibility summaries or an equivalent readable data list.

## 7. Sign-off

- [ ] Record all failures with fictional data only.
- [ ] Record iOS version and device model for each Shortcuts/notification limitation.
- [ ] Re-run the full macOS/Xcode unit and UI test workflow after fixes.
- [ ] Do not merge, release, or describe the app as production-ready until test evidence is reviewed and explicit approval is given.
