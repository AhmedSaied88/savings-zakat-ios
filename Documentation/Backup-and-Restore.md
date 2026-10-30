# Encrypted backup and restore

## Format and protection

The native app exports a versioned JSON envelope containing encrypted finance snapshot bytes. The envelope includes the backup version, KDF identifier and parameters, random salt, AES-GCM nonce, ciphertext and authentication tag. Account names, balances, transactions and other finance records are not exposed as plaintext in the envelope.

- Passphrase key derivation: PBKDF2-HMAC-SHA256, 600,000 iterations, 16-byte random salt.
- Encryption and authentication: AES-256-GCM with a 12-byte nonce and authenticated context.
- The archive validates its version, KDF parameters, nonce/tag/salt sizes and finance schema before accepting data.
- A modified archive or incorrect passphrase fails authentication.
- Export is written through the iOS document picker to a user-selected location. No upload or cloud sync is performed by the app.

Use a unique passphrase of at least 12 characters. The app does not store it. Keep the backup file and passphrase separately. If the passphrase is lost, the encrypted backup cannot be recovered.

## Export

1. Open the **Settings** tab and choose **Backup & Restore**.
2. Enter a strong passphrase and confirm it.
3. Tap **Export encrypted backup**.
4. Save the resulting JSON file in Files or another location you control.
5. Keep the passphrase somewhere separate from the file.

## Restore

1. Open **Settings → Backup & Restore**.
2. Enter the passphrase used when the backup was created.
3. Choose the encrypted backup file.
4. Wait for authentication and schema validation.
5. Review the replacement warning and explicitly confirm **Replace local records**.

Restore replaces the current finance snapshot; it does not merge records. If authentication or validation fails, the restore is not applied. The finance snapshot is saved atomically through the local finance store.

## Scope of this first version

Included: accounts, cards, transactions, liabilities, cash/gold/silver/manual-investment holdings, manual exchange rates, gold/silver prices, Nisab input, personal-use gold setting and custom bank-message parser rules in the finance snapshot.

Not included: pending bank-message review queue and notification schedules. The imported-message queue is stored separately and is not overwritten by restore. Recreate local Hawl reminders after restoring or correcting asset dates.

This feature has unit tests for encrypted round-trip, wrong passphrase, malformed archives, unsupported versions/schema, unsafe KDF parameters, ciphertext tampering, random salt generation and local file writing. Xcode test execution remains subject to the repository's current macOS runner availability.
