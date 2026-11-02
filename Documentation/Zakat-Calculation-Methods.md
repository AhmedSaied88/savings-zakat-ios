# Zakat calculation method comparison

**Status:** Implemented in the native iOS feature branch; automated verification is pending.

The app presents two calculation conventions side by side. They are calculation mechanics selected for comparison, not a fatwa or a claim that one method is universally accepted. Scholarly views can differ; users should confirm the method and Nisab basis they follow with a trusted scholar.

## Shared rules

- All valued holdings are converted to EGP using the rates and exact-carat metal prices entered in the app.
- Each holding retains its own Gregorian Hawl start date. Its Egyptian Hijri equivalent and confidence remain subject to the calendar source/estimate rules.
- A holding enters eligible wealth only after its own Hawl due date has completed on the Cairo civil day.
- Personal-use gold remains excluded unless the user enables the existing preference.
- A missing exchange rate, metal price, invalid holding, invalid Nisab or estimated Hawl date produces a visible warning and/or provisional result. The app does not invent missing inputs.
- The same configured EGP Nisab is used in both comparison methods.

## Method A — Independent categories

Eligible matured holdings are grouped into these app categories:

1. Cash and currencies
2. Gold (all supported carats, valued in EGP)
3. Silver (purity-adjusted and valued in EGP)
4. Investments

Each category is compared independently with the full configured Nisab. If that category reaches Nisab, the app calculates 2.5% of that category's matured eligible value. A category below Nisab contributes zero under this method, even if the sum of categories would exceed Nisab.

The category grouping is an explicit software assumption for this comparison; it must not be presented as a universal scholarly classification.

## Method B — Separate Hawl, combined Nisab

Each holding is still assessed against its own Hawl start date. Only holdings whose individual Hawl has matured are included. The app then combines all matured eligible categories, compares the combined amount with Nisab, and calculates 2.5% of that combined matured amount when the threshold is met.

This method does not reset all holdings to one common Hawl date. Unmatured holdings remain visible in the asset breakdown but are excluded from the current matured eligible total.

## Selecting and saving a result

- Both results are displayed together after the user taps **Calculate Zakat**.
- The user chooses which method to use. The selected method is stored in local finance preferences.
- **Save selected result** stores an immutable snapshot containing the chosen method, calculation date, valued totals, Nisab, Zakat amount, warnings, per-holding and per-category breakdowns, asset records, exchange rates, metal prices and personal-use-gold setting.
- Later edits to assets, rates or prices do not silently recalculate or overwrite the saved snapshot. The user must explicitly save again to replace it.
- The snapshot is part of the local finance preferences and therefore follows the existing encrypted backup/restore scope.

## Verification

Automated tests cover:
- Cases where independent categories are each below Nisab but combined matured wealth reaches Nisab.
- Cases where one category reaches Nisab and another does not.
- Per-holding Hawl maturity, including exclusion before maturity and inclusion on the due date.
- Backward-compatible decoding of existing preferences without the new optional fields.
- Round-trip persistence of the selected method and saved calculation snapshot.

Physical-device review remains required before release.