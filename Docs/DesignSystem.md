# Design System

TaskFlow uses a **grayscale-only** palette with **semantic roles**.

## Colors

All UI colors must come from `AppTheme.colors` (`TaskFlow/DesignSystem/Colors.swift`).

### Roles

- **Text**
  - `textPrimary`: default text
  - `textSecondary`: supporting / metadata text
  - `textDisabled`: disabled text
  - `textOnPrimaryAction`: text/icons on `primaryAction`
- **Background / Surface**
  - `appBackground`: app canvas behind scroll views and lists
  - `surface`: primary surface (cards, inputs)
  - `surfaceElevated`: elevated surface (cards with borders/shadows)
  - `secondaryBackground`: subtle fill for lightweight controls
  - `fillSubtle`: translucent overlay for pressed/selected states
- **Borders**
  - `border`: default stroke
  - `borderSubtle`: lighter stroke (e.g. text fields)
  - `divider`: separators

### Status colors (still grayscale)

`success`, `warning`, and `error` are intentionally grayscale. Prefer text/icon + copy for status communication.

