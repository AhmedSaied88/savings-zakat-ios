# Bank SMS import with Apple Shortcuts

## iOS limitation

Savings & Zakat does not read the iPhone Messages inbox. iOS does not provide ordinary third-party apps with unrestricted access to SMS history. The supported workflow is user-controlled: a user-created Shortcuts automation can pass the text of a selected bank message to the app, or the user can copy/paste a message manually.

## Recommended user flow

1. Open Shortcuts and create a Personal Automation for Message.
2. Choose the bank sender or sender filter if the bank uses a stable sender ID.
3. Add an action to pass the message body to the Savings & Zakat import flow (use the app's supported App Intent / shortcut action when available).
4. Review the parsed amount, currency and direction inside the app.
5. Confirm the transaction before it affects the user's ledger.

The exact available automation options depend on iOS version, device settings and the bank's sender format. If the automation cannot run unattended, use the manual share/copy-and-paste route.

## Privacy and parsing rules

- Parsing happens on-device.
- Imported messages are never treated as confirmed transactions automatically.
- The parser retains only redacted source text in its result.
- Long card-like number sequences and OTP/CVV/PIN values are redacted.
- Never ask users to provide a full card number, CVV, PIN, OTP, bank password or online-banking credentials.
- Unknown message formats must be rejected for manual review rather than guessed.
- No external SMS gateway or paid SMS service is used.

## Current implementation status

The local parser is deliberately conservative and recognizes a limited set of English/Arabic transaction keywords and common currency amount formats. It is not a universal parser for every Egyptian bank. An App Intent / Shortcut action and the in-app review/confirmation screen are still required before this workflow is end-to-end.
