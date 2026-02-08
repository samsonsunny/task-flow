# Design Rules – Source of Truth

**Purpose:** Establish clear, consistent, and scalable design decisions for TaskFlow. These rules define how the product should look, feel, and behave so that every screen and component ships with the same quality bar. This document defines the UI and UX rules for this app. All screens, components, and features MUST follow these rules.

**The Goal Is:**
*   Visual consistency
*   Predictable UX
*   Fast iteration with AI assistance
*   Minimal refactoring

---

## 1. Core Principles (Non-Negotiable)

These principles guide all design decisions for TaskFlow. When in doubt, default to the simplest option.

*   **Clarity over Cleverness:** Every screen must be understandable within 3 seconds.
*   **Focused Flow:** Each screen should have one primary action; secondary actions must be visually quieter.
*   **Calm, Confident UI:** Prioritize purposeful whitespace and avoid visual noise.
*   **Consistency is Key:** Maintain visual and behavioral consistency. Break patterns only with documented rationale.
*   **Accessibility First:** Ensure contrast, hit targets, and text sizes meet or exceed WCAG AA standards.
*   **Reuse over Reinvention:** Leverage existing components and patterns whenever possible.
*   **Native iOS Behavior by Default:** Respect platform conventions for a familiar user experience.

---

## 2. Design System Usage (Mandatory)

To ensure visual consistency, predictable UX, and fast iteration, all UI implementations MUST adhere to the defined Design System.

*   **Colors:** All colors MUST be sourced from `DesignSystem/Colors.swift`. Do NOT use hardcoded color values.
*   **Spacing:** All spacing values MUST utilize constants from `DesignSystem/Spacing.swift`.
*   **Typography:** All fonts and text styles MUST use helpers and definitions from `DesignSystem/Typography.swift`.
*   **Component Styling:** Corner radius, shadows, and elevation MUST use predefined constants from the Design System.
*   **Avoid Magic Numbers:** Do NOT introduce hardcoded numeric values for UI properties (e.g., padding, font sizes, colors) directly within screen implementations.

**Example:**
❌ **Not Allowed:**
```swift
.padding(14)
.foregroundColor(.blue)
.font(.system(size: 17))
```
✅ **Allowed:**
```swift
.padding(Spacing.sm)
.foregroundColor(AppColors.primary)
.font(AppFont.body())
```

---

## 3. Components

*   **Components First Principle:**
    *   Before implementing new UI, always check for existing reusable components.
    *   If a suitable component exists, reuse it.
    *   If no suitable component exists, create it as a reusable component *first* before integrating it into a screen.
    *   Screens SHOULD NOT contain heavy styling logic; delegate styling to components.
    *   **Examples of reusable components:** `PrimaryButton`, `SecondaryButton`, `CardView`, `AppTextField`, `EmptyStateView`.

*   **Buttons:** Define one primary, one secondary, and one tertiary text style. Refer to "Button & Action Rules" for interaction guidelines.
*   **Inputs:** Labels must always be visible; placeholders serve as hints, not replacements for labels.
*   **Lists:** Primary text should be left-aligned; secondary text can be below or right-aligned.
*   **Cards:** Use sparingly and only when they effectively add hierarchy or group related content. Avoid "card sprawl."
*   **Icons:** Maintain consistent stroke weight and optical size. Ensure icons align to the 8-pt grid.

---

## 4. Layout & Spacing

*   **Grid System:** Utilize an 8-point grid for all measurements. Spacing increments should be multiples of 4 or 8 (e.g., 4, 8, 12, 16, 24, 32, 40, 48).
*   **Base Screen Padding:** Apply standard screen padding (e.g., 24pt on iOS, 20pt on compact screens) for horizontal margins.
*   **Vertical Rhythm:** Stack content using 8-pt increments and align to common baselines to maintain a consistent vertical flow.
*   **Content Width:** Keep primary content within a max readable width to ensure legibility; avoid edge-to-edge text.
*   **Lists:** Apply 12–16pt vertical padding per row and 16pt between groups.
*   **Layout Structure:**
    *   Avoid deeply nested layouts.
    *   Prefer `VStack`, `HStack`, and `ZStack` for common geometry over custom layout implementations.
    *   Use `ScrollView` only when content is expected to overflow the screen bounds.

---

## 5. Color & Contrast

*   **Semantic Colors:** Use semantic colors exclusively (e.g., `primary`, `background`, `textPrimary`). Do not use raw color values.
*   **Brand Palette:** Define one primary brand color and one accent color. All other colors should be neutral.
*   **Contrast:** Text contrast MUST meet or exceed WCAG AA guidelines for accessibility.
*   **State Definition:** Clearly define all four states for interactive elements: default, hover/focus, pressed, and disabled.
*   **Meaning Conveyance:** Do not use color as the sole indicator of state or meaning; provide alternative indicators.
*   **Black Usage:** Avoid pure black (`#000000`); use near-black for improved readability and a calmer UI.
*   **Gradients & Opacity:** Avoid gradients unless explicitly approved. Exercise caution with opacity manipulation on text colors to maintain legibility.

---

<h2>6. Typography</h2>

*   **Font Source:** Utilize the app’s existing system font or a defined brand font. Avoid introducing new fonts without clear consensus.
*   **Type Scale:** Adhere to the defined type scale:
    *   Display: 32 / 40, semibold
    *   H1: 24 / 32, semibold
    *   H2: 20 / 28, semibold
    *   Body: 16 / 24, regular (default)
    *   Caption: 13 / 18, regular
*   **Hierarchy:** Establish hierarchy primarily through font weight; use color as a secondary indicator.
*   **Titles:** Use titles sparingly, reserving them for major sections or prominent features.
*   **Font Families:** Do not mix font families within the application.
*   **Overrides:** Avoid manual font size or style overrides directly in screens; use typography helpers from the Design System.
*   **Line Height:** Follow system default line heights unless a specific design rationale dictates otherwise.
*   **All Caps:** Avoid all-caps text except for short, clear labels (<= 8 characters).

---

## 7. Interaction & Motion

*   **Purposeful Motion:** Motion and animations MUST communicate state changes or guide user attention, not serve as mere decoration. If an animation is not necessary, do not add it.
*   **Animation Types:** Prefer system or spring animations.
*   **Timing:**
    *   Micro-transitions (e.g., button presses): 150–250ms.
    *   Screen transitions: 250–400ms.
    *   Animation duration should be subtle.
*   **Easing:** Prefer subtle easing curves (e.g., ease-out). Avoid bouncing unless the design explicitly aims for a playful tone.
*   **User Interaction:** Motion should never block or impede user interaction.
*   **Decorative & Infinite Animations:** Avoid purely decorative or infinite loop animations.
*   **Focus States:** Focus states for interactive elements MUST be visible during keyboard navigation.

---

<h2>8. Accessibility & Usability</h2>

*   **Minimum Tap Target:** Ensure all interactive elements have a minimum tap target size of 44x44 points.
*   **Dynamic Type:** Support Dynamic Type to allow users to adjust text sizes.
*   **Reduced Motion:** Respect system-wide reduced motion settings.
*   **Color Contrast:** Maintain sufficient color contrast, meeting or exceeding WCAG AA standards.
*   **Redundant Indicators:** Do not rely on color alone to convey meaning or state; provide alternative indicators.
*   **Screen Readers:** Every interactive element must have a clear, descriptive label for screen readers.
*   **iOS Human Interface Guidelines:** Adhere to the iOS Human Interface Guidelines for platform-specific accessibility best practices.

---

<h2>9. Button & Action Rules</h2>

*   **Primary Action:** Each screen should feature one clear primary action, which must be visually dominant.
*   **Secondary Actions:** Secondary actions should not visually compete with the primary action.
*   **Destructive Actions:** Do not place destructive actions (e.g., "Delete") immediately adjacent to primary actions.
*   **Touch Targets:** Button touch targets MUST be ≥ 44pt.

---

<h2>10. Content & Tone</h2>

*   **Concise & Action-Oriented:** Be concise and use action-oriented language (verbs over nouns).
*   **Error Messages:** Explain what happened and provide clear instructions on what to do next.
*   **Avoid Jargon:** Use clear, simple language that resonates with the user.
*   **Confirmation Dialogs:** Clearly state the impact of an action and provide an obvious way to cancel or exit.

---

<h2>11. Data Density</h2>

*   **Progressive Disclosure:** Prefer progressive disclosure to manage complexity and avoid overwhelming users.
*   **Power Users:** Provide optional compact views for power users, but do not make them the global default.
*   **Tables:** Align numbers right, text left. Use zebra striping only if necessary to improve readability of dense data.

---

<h2>12. Platform Fit (iOS)</h2>

*   **Native Conventions:** Respect native iOS conventions for navigation, back behavior, and modal patterns.
*   **Native Controls:** Use native controls unless there is a clear product reason or established design system component to use a custom alternative.
*   **Safe Areas:** Do not fight safe areas; ensure content breathes and is not obstructed by system UI.

---

<h2>13. What NOT to Do (Anti-Patterns)</h2>

*   **Do Not Invent:** Avoid creating new colors, spacing values, font styles, or component variants not defined in the Design System.
*   **Do Not Hardcode:** Never hardcode UI constants (e.g., specific padding values, colors, font sizes) directly within screen implementations.
*   **Do Not Over-Design:** Resist the urge to over-design early features. Prioritize functionality and clarity.
*   **Do Not Sacrifice Clarity for Aesthetics:** Aesthetics are important, but never at the expense of clarity and usability.

---

<h2>14. Review & Governance</h2>

*   **Review Checklist (Before Shipping):**
    *   Is the primary action obvious within 3 seconds?
    *   Does spacing adhere to the 8-pt grid and Design System values?
    *   Does text pass contrast requirements and exhibit correct hierarchy?
    *   Are all relevant states (empty, loading, error, success) designed and implemented?
    *   Are tap targets and focus states accessible?
    *   Is motion purposeful and does it respect reduced-motion settings?

*   **Rule Evolution:**
    *   New patterns or deviations require a brief design note with screenshots and a clear rationale.
    *   If a rule is broken and proves to be a better standard, document why and update this file.
    *   Rules should be updated only when:
        *   A new reusable pattern is proven across multiple screens.
        *   A clear UX problem is identified and a new rule provides a solution.
        *   A design decision has a significant, long-term impact on the product.
    *   Changes to these rules should be deliberate and well-considered, not reactive.

---

**Final Ruling:** If a rule conflicts with usability or accessibility, usability wins.