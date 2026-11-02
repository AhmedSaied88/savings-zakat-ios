# Apple Shortcuts: bank-message import

## What this integration does

Savings & Zakat provides an App Intent named **Import Bank Message**. A user-created Shortcuts Message automation can pass the message body and, where available, the sender identifier to this action. The intent opens the app and stores a redacted copy in the local review queue.

The app does **not** read the Messages inbox, request unrestricted SMS access, or send message contents to a server. The intent records the time it was invoked; it does not claim to know the original SMS delivery timestamp unless the user supplies that separately in a future version.

## Create a Message automation

1. Open **Shortcuts** and choose **Automation**.
2. Create a **Message** personal automation.
3. Select the bank sender or a suitable sender filter, if available on your iOS version.
4. Add the Savings & Zakat **Import Bank Message** action.
5. Pass the message body into **Message text** and the sender into **Sender identifier** when the automation exposes those values.
6. Choose whether the automation should ask before running. iOS may require confirmation or restrict unattended execution depending on iOS version, device settings and the automation type.
7. Test with a fictional message first. Confirm that it appears in the app's review queue.

If the Message trigger does not expose the message body or cannot run as needed on your device, use the manual fallback: copy the bank message, open Savings & Zakat, and use the import action from Shortcuts with the copied text.

## Privacy and transaction safety

- The intent passes text directly to an on-device coordinator.
- OTP, PIN, CVV, password and card-like number patterns are redacted before the queue file is written.
- The original unredacted message is not stored by this feature.
- Queue data is written atomically to the app's Application Support directory.
- Duplicate delivery is checked using sender identifier + redacted-content fingerprint + a five-minute received-time window. This reduces repeated automation deliveries; it cannot identify every real-world duplicate transaction.
- Unknown formats are retained as redacted items for manual review, without guessed amount or direction.
- Every imported item starts in needsReview. Importing a message never posts a transaction or changes a balance.

## iOS limitations

This is a user-configured Shortcuts bridge, not direct SMS inbox access. Apple changes automation behavior across iOS versions, and some automations may ask for confirmation or may not run unattended. Sender/body variables can also differ by trigger and iOS version. The exact steps must be validated on the physical iPhone and iOS version in use before relying on automatic delivery.
