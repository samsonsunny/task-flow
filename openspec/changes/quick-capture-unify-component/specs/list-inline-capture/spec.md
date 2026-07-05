## MODIFIED Requirements

### Requirement: Shared QuickCaptureRow component

The system SHALL use a shared `QuickCaptureRow` component (defined in `Views/Components/QuickCaptureRow.swift`) for all inline quick capture fields. The component SHALL:

- Accept `@Binding text`, `onSubmit: (String) -> Void` callback, and `onDismiss: () -> Void` callback
- Own `@FocusState` internally — no binding passed from parent
- Render as a row with a filled circle and text field
- Have `.id("quick-capture")` for scroll anchoring
- Use `.transition(.move(edge: .bottom).combined(with: .opacity))`
- Dismiss on tap-away (handled internally via `onChange(of: isFocused)`)

#### Scenario: Component handles commit and dismiss internally
- **WHEN** the user presses return after typing text
- **THEN** the component clears the text, re-focuses for rapid entry, and calls `onSubmit(text)` with the committed text

- **WHEN** the user taps outside the field (focus lost)
- **THEN** the component commits the text if non-empty via `onSubmit(text)`
- **AND** calls `onDismiss()` for parent cleanup
- **AND** clears the text binding
