## 1. Update TimelineView.swift

- [x] 1.1 Remove chevron button from `quickCaptureRow`
- [x] 1.2 Delete `openQuickCaptureEditor()` method
- [x] 1.3 Change `onChange(of: isQuickCaptureFocused)` — commit on defocus, keep row alive
- [x] 1.4 Re-add `onChange(of: tasks)` — no racing issue with stable row

## 2. Update DetailView.swift

- [x] 2.1 Remove chevron button from `quickCaptureRow`
- [x] 2.2 Delete `openQuickCaptureEditor()` method
- [x] 2.3 Change `onChange(of: isQuickCaptureFocused)` — commit on defocus, keep row alive

## 3. Verify

- [x] 3.1 Build with `xcodebuild`
- [ ] 3.2 Run UI test if one exists
