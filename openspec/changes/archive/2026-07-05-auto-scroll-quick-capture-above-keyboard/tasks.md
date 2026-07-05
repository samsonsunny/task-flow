## 1. Create change artifacts

- [x] 1.1 Create change directory and `.openspec.yaml`
- [x] 1.2 Write `proposal.md`
- [x] 1.3 Write `design.md`
- [x] 1.4 Write `tasks.md`

## 2. Update QuickCaptureRow.swift

- [x] 2.1 Import `Combine` (needed for `onReceive` with publisher)
- [x] 2.2 Add `keyboardDidShowNotification` listener to `quickCaptureScroll` modifier
- [x] 2.3 Guard with `isActive` check to skip unnecessary scrolls
- [x] 2.4 Animate the scroll with `easeOut(duration: 0.25)`

## 3. Verify

- [x] 3.1 Build — exit code 0 (pre-existing warning unrelated)
- [ ] 3.2 Manual: FAB tap → row appears → keyboard covers → row re-scrolls above keyboard
- [ ] 3.3 Manual: Focus away and back → re-scrolls correctly
