# Local Hawl reminders

## Schedule

Savings & Zakat uses iOS local notifications only. No server or paid notification provider is involved.

For each asset with a calculable Hawl due date, the reminder planner creates stable notification identifiers based on the asset ID and offset:

- 30 days before
- 7 days before
- 1 day before
- On the due date

Reminders are scheduled for 9:00 AM local device time on the matching Cairo Gregorian civil date. If a reminder date has already passed, that notification is skipped. The Hawl date and confidence status shown in the app remain the source of truth.

## Permission and delivery

The app requests alert/sound permission only when the user taps **Schedule / refresh reminders**. If permission is denied, no new schedule is written and the existing pending reminders are left untouched. The user can enable notifications in iPhone Settings and retry.

Local delivery remains subject to iOS notification settings, Focus modes, device availability and system behavior. A scheduled local notification is not a guaranteed alarm.

## Rescheduling and cancellation

- Tapping **Schedule / refresh reminders** replaces the app's existing Hawl reminder set with the current asset dates and current device time zone.
- Editing an asset cancels its old reminders; refresh the schedule to create reminders for the corrected Hawl date.
- Deleting an asset cancels that asset's pending reminders.
- **Cancel all Hawl reminders** removes only notifications whose identifiers use the app's `hawl.` prefix; unrelated app notifications are not removed.
- Changing the device time zone requires a reminder refresh to rebuild the local 9:00 AM fire times.

## Date confidence

The reminder body identifies the asset and Gregorian due date. The calendar screen separately displays the Hijri equivalent and Confirmed/Estimated status. An estimated Hawl date remains estimated in the UI; notification scheduling does not upgrade its confidence.
