# Bank SMS import with Apple Shortcuts

See also the implementation-specific setup guide: [Apple Shortcuts SMS Setup](Apple-Shortcuts-SMS-Setup.md).

## iOS limitation

Savings & Zakat does not read the iPhone Messages inbox. iOS does not provide ordinary third-party apps with unrestricted access to SMS history. The supported workflow is user-controlled: a user-created Shortcuts automation can pass the text of a selected bank message to the app, or the user can copy/paste a message manually.

## Recommended user flow

1. Open Shortcuts and create a Personal Automation for Message.
2. Choose the bank sender or sender filter if the bank uses a stable sender ID.
3. Add the Savings & Zakat **Import Bank Message** App Intent and pass the message body and sender identifier when the Message trigger exposes them.
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

The local parser is deliberately conservative. It recognizes supported EGP/LE and major foreign-currency amount formats before or after the amount; English and Arabic-Indic digits; and common credit, debit, ATM withdrawal, POS purchase, transfer, bank-fee, reversal/refund and card-payment keywords. It rejects unknown formats, conflicting direction signals and messages with multiple monetary amounts rather than guessing which amount is the transaction.

Sensitive values are redacted before the imported-message model retains source text. The parser computes a deterministic SHA-256 fingerprint from the redacted, normalized message text. This content fingerprint is only one deduplication signal: the future Shortcut coordinator must combine it with the sender identifier and a received-time window to avoid suppressing a legitimate repeated transaction. Parsed messages remain in `needsReview` state; the parser does not post transactions to the ledger.

This is not a universal parser for every Egyptian bank. Bank-specific fixtures and real-world validation with fictionalized/redacted examples are still required. An App Intent / Shortcut action and the in-app review/confirmation screen are still required before this workflow is end-to-end.
