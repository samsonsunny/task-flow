## Context

The reminder editor (`EditorView.swift:115-117`) currently renders notes as:

```swift
TextField("Notes", text: draftBinding.notes, axis: .vertical)
    .lineLimit(1...4)
```

This limits visible content to 4 lines. On small-screen devices (iPhone SE, mini), 4 lines of a `TextField` is ~80pt — insufficient for reviewing or editing multi-line notes. The same control is used in both create and edit flows since they share `ReminderEditorView`.

The `Draft.notes` field is a plain `String` — no data model changes needed. The `TaskRowView` display (4-line `Text` with ellipsis) is appropriate for a summary row and stays unchanged.

## Goals / Non-Goals

**Goals:**
- Replace the 4-line `TextField` with an auto-growing `TextEditor` that expands with content
- Cap visible area at ~200pt (~8-10 lines) with internal scrolling beyond that
- Show a placeholder when notes are empty (TextEditor has no native placeholder)
- Work identically in create and edit flows (shared `ReminderEditorView`)
- Maintain existing Draft binding and save/discard behavior

**Non-Goals:**
- Changing `TaskRowView` notes display (stays at 4 lines)
- Rich text / markdown support (future consideration)
- Separate full-screen notes editor (overkill for current use cases)
- Modifying the `Draft` model or `EditorViewModel` save logic

## Decisions

### D1: TextEditor over TextField(axis:)

**Choice:** `TextEditor` with overlay placeholder

**Why:** `TextField(axis: .vertical)` with `.lineLimit()` is designed for short multi-line input (chat bubbles, search fields). It doesn't natively support scrollable content beyond the line limit. `TextEditor` is a `UIViewRepresentable` wrapping `UITextView` — it scrolls natively, has no line limit by default, and grows with content. The tradeoff is that `TextEditor` has no placeholder, but this is solved with a simple overlay.

**Alternatives considered:**
- Increasing `.lineLimit(1...8)` on TextField — still a hard cap, still fights on small screens
- `.lineLimit(nil)` on TextField — removes max but doesn't add scrolling; field grows unbounded
- Dedicated full-screen notes sheet — extra navigation step, over-engineered for v1

### D2: maxHeight: 200 as the scroll cap

**Choice:** `.frame(maxHeight: 200)` on the TextEditor

**Why:** 200pt ≈ 8-10 lines at the default TextEditor font size. This leaves enough room for title (~44pt), URL field (~44pt), and metadata rows (~130pt) on a 350pt usable-height screen (iPhone SE). Beyond 200pt, the TextEditor scrolls internally. This is a pragmatic cap that works across all device sizes.

**Alternatives considered:**
- No cap — TextEditor grows unbounded, pushes all metadata off-screen on long notes
- UIScreen.main.bounds.height * 0.4 — dynamic but fragile with keyboard changes
- Fixed 150pt — too tight for 6-7 line notes

### D3: Placeholder via overlay, not UITextView configuration

**Choice:** Conditional overlay with `Text("Notes").foregroundStyle(.placeholder)` when `draft.notes.isEmpty`

**Why:** `TextEditor` wraps `UITextView` which does have a `placeholder` property on iOS 17+, but accessing it requires `UIViewRepresentable` coordination. A SwiftUI overlay is simpler, stays in pure SwiftUI, and matches the existing `TextField` placeholder styling.

**Alternatives considered:**
- UITextView.placeholder via UIViewRepresentable bridge — more complex, no visual benefit
- Separate state for "has typed" — unnecessary; checking `draft.notes.isEmpty` is sufficient

## Risks / Trade-offs

- **[Risk] TextEditor styling differences from TextField** → TextEditor has different default padding, font, and background than TextField. Mitigation: Apply `.font(.body)`, `.scrollContentBackground(.hidden)` if needed, and test visual parity with the existing TextField.

- **[Risk] Keyboard interaction changes** → TextEditor handles keyboard differently than TextField (no `.submitLabel`, different focus behavior). Mitigation: The notes field doesn't use `.submitLabel` today; focus is on the title field, not notes. Low impact.

- **[Trade-off] Slightly more code for placeholder** → TextField had built-in placeholder; TextEditor needs an overlay. ~5 lines of extra code. Acceptable.

- **[Trade-off] Internal scrolling vs full expansion** → User can't see all long notes at once without scrolling. Acceptable because: (a) the cap is generous at 200pt, (b) the alternative (unbounded growth) is worse on small screens.
