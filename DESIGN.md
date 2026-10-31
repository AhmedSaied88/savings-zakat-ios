---
version: alpha
colors:
  primary: "#1F57C7"
  primarySurface: "#EDF5FF"
  secondary: "#6E52B8"
  assetGold: "#AD7514"
  darkPrimary: "#85ADFF"
  darkPrimarySurface: "#172640"
  darkSecondary: "#C2ADFF"
  darkAssetGold: "#FFCC66"
  income: "#176B45"
  expense: "#994D00"
  warning: "#8A4A00"
  danger: "#B52417"
  darkIncome: "#6EDBA1"
  darkExpense: "#FFB36B"
  darkWarning: "#FFC980"
  darkDanger: "#FF8A80"
typography:
  display:
    fontFamily: "SF Pro Display, system-ui, sans-serif"
  body:
    fontFamily: "SF Pro Text, system-ui, sans-serif"
  data:
    fontFamily: "SF Mono, ui-monospace, monospace"
rounded:
  card: "16px"
  tile: "14px"
  icon: "10px"
spacing:
  compact: "8px"
  row: "12px"
  section: "16px"
  screen: "20px"
components:
  primaryAction:
    style: "native borderedProminent"
    tint: "#1F57C7"
  screen:
    style: "native insetGrouped list or form"
  walletSummary:
    style: "pale-blue rounded summary surface"
omitted:
  - section: elevation
    reason: "Native grouped surfaces and system materials own elevation; avoid decorative shadow stacks."
---

# Overview

Savings & Zakat is a native iPhone personal-finance tool for people who need a quick, trustworthy view of accounts, cards, transactions, debts, savings assets, Hawl and Zakat. Its visual register is **product-first**: clear financial hierarchy and familiar iOS interaction take priority over decorative brand expression.

The approved direction is **Design 4's compact wallet composition with Design 3's blue palette**. The interface should feel like a carefully organized personal wallet: calm, precise, familiar, and safe around sensitive financial information.

The signature is the Wallet net-worth summary: one pale-blue surface that gives the key number clear prominence, with assets and debts as compact supporting measures. Keep the rest of the interface quiet so this one financial anchor remains easy to find.

Anti-references: dense stacks of floating cards, gradients behind every section, ornamental charts, tiny utility text, bright gold used for body copy, custom controls that imitate native iOS pickers, and any visual treatment that hides provisional or estimated financial information.

# Colors

- **Royal blue** is the primary action, selected navigation and key financial emphasis.
- **Pale blue** is reserved for the Wallet summary and small supporting surfaces; it must adapt to a deep navy tint in Dark Mode.
- **Violet** distinguishes debts and secondary financial categories; it is not an error color.
- **Gold** identifies gold/metal assets and is an accent, not the default text color.
- Income `#176B45`, expense `#994D00`, warning `#8A4A00`, and danger `#B52417` are the Light Mode semantic text colors. Their Dark Mode counterparts are `#6EDBA1`, `#FFB36B`, `#FFC980`, and `#FF8A80`.
- Always pair status color with explicit text or a symbol. Status colors are tested against system, grouped, and pale-blue surfaces in both appearances.
- Screen and row surfaces use UIKit's dynamic `systemGroupedBackground`, `secondarySystemGroupedBackground`, and `systemBackground`; separators use `separator`. Do not hard-code a white screen background in Dark Mode.

Runtime mapping: `FinancePalette` in `SavingsZakat/Views/FinanceTabs.swift` is the canonical implementation of expressive and semantic colors with dynamic light/dark values. `FinancePalette.canvas`, `whiteSurface`, `groupedSurface`, and `separator` map to UIKit semantic surfaces. `financeScreenSurface()` applies the shared scroll background and royal-blue tint to all List and Form screens. `FinancePaletteTests` verifies text and non-text contrast pairs in both appearances. Do not duplicate these values in individual views.

# Typography

Use the system San Francisco family and native Dynamic Type. The large Wallet net-worth amount is the only prominent display treatment. Use headline weight for account/asset names, subheadline for amounts and row summaries, and footnote/caption for secondary dates and explanations. Financial amounts use monospaced digits where comparison or scanning matters. Never shrink text to preserve a single line; allow wrapping at accessibility sizes.

# Layout

- Five persistent tabs: Wallet, Accounts, Activity, Debts, and Zakat.
- Use native `NavigationStack`, `List`, `Form`, `Section`, `NavigationLink`, `Menu`, `DatePicker`, `Picker`, `Toggle`, and sheet presentation.
- Main list screens use inset-grouped sections on the system grouped canvas. Forms use the same canvas and shared tint.
- Keep rows compact but tappable; target a minimum 44×44-point touch area for primary custom controls.
- Use a consistent vertical rhythm: 8 points for related content, 12 for row groups, 16 for section separation, and 20 for major screen insets.
- Keep long forms naturally scrollable. Do not constrain a shared screen ancestor to a fixed height.
- The Wallet summary sits first; accounts, recent activity and quick overview follow. Avoid repeating the same total in multiple places.
- Charts must have a readable text equivalent and must not be the only way to understand income/expense values.

# Elevation & Depth

Native grouped list and form materials provide separation. Use no decorative shadow for static financial rows. The Wallet summary and quick overview tiles may use a quiet rounded surface, but do not build nested cards inside cards.

# Shapes

Use continuous rounded rectangles: 16-point Wallet summary, 14-point compact overview tiles, and 10-point icon wells. Native buttons, pickers, toggles, sheets and tab bars retain platform-owned shapes.

# Components

- **Wallet summary:** one pale-blue rounded surface; net worth first, then assets/debts, then a clear caveat if valuations are incomplete.
- **Account/card rows:** recognizable SF Symbol, name, institution/type, and right-aligned monospaced balance; cards show masked digits only.
- **Transaction rows:** direction is communicated in text for assistive technology as well as by a visual icon; amounts remain easy to scan.
- **Asset rows:** asset-specific accent, descriptive type/weight, Gregorian dates, valuation state, and Hawl maturity/status.
- **Estimated/confirmed states:** always include words such as “Estimated” or “Confirmed”; color is supplementary.
- **Primary action:** native bordered-prominent button with royal-blue tint. Toolbar icon actions must have an accessible label and at least 44×44-point frame.
- **Forms:** native labels, controls, validation and navigation actions. Never use placeholder-only instructions for sensitive or required fields.

# Do's and Don'ts

- Do keep financial amounts, currency codes and due dates explicit.
- Do state when a value is provisional or unvalued.
- Do retain the same hierarchy in Light and Dark Mode.
- Do allow content to grow at large Dynamic Type sizes.
- Do label icon-only controls and hide purely decorative icons from VoiceOver.
- Don't use gold as small body text on pale surfaces.
- Don't communicate income, expense, warning, maturity or confirmation by color alone.
- Don't store or display full card numbers, CVV, PIN, OTP or bank credentials.
- Don't use a visual redesign to change ledger, reminder, calendar or Zakat behavior.
