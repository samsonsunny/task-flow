## 1. QuickCaptureRow — Implement keyboard chaining

- [ ] 1.1 Add `.submitBehavior(.stay)` to the `TextField` in QuickCaptureRow
- [ ] 1.2 Rewrite `handleSubmit()`: empty text → dismiss (set `isFocused = false` + call `onDismiss()`); non-empty → commit + stay focused (remove `isFocused = true` workaround)

## 2. Update live specs

- [ ] 2.1 Update `openspec/specs/list-inline-capture/spec.md`: add "keyboard stays visible" to commit scenarios; change empty-Return from "field remains visible" to "field is dismissed"
- [ ] 2.2 Update `openspec/specs/upcoming-inline-capture/spec.md`: add "keyboard stays visible" to commit scenario

## 3. Verify

- [ ] 3.1 Run full UI test suite and confirm all tests pass
