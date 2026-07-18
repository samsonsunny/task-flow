## 1. Create flow — Inline TextEditor (done)

- [x] 1.1 Replace notes TextField with TextEditor
- [x] 1.2 Remove .lineLimit(1...4)
- [x] 1.3 Add .frame(minHeight: 36, maxHeight: 200)
- [x] 1.4 Add .font(.body)

## 2. Create flow — Placeholder overlay (done)

- [x] 2.1 Wrap TextEditor in ZStack(alignment: .topLeading)
- [x] 2.2 Add conditional "Notes" placeholder
- [x] 2.3 Add padding to align with TextEditor insets

## 3. Edit flow — Notes preview card

- [x] 3.1 Add @State isNotesSheetPresented to ReminderEditorView
- [x] 3.2 Create notesPreviewCard computed property: shows first 4 lines of draft.notes or "Add notes" placeholder, with trailing chevron
- [x] 3.3 In contentSection, conditionally render: create → inline TextEditor, edit → notesPreviewCard
- [x] 3.4 Add tap gesture on preview card to set isNotesSheetPresented = true

## 4. Edit flow — Notes sheet

- [x] 4.1 Add .sheet(isPresented: $isNotesSheetPresented) with full-screen TextEditor bound to draftBinding.notes
- [x] 4.2 Sheet uses .presentationDetents([.large]) for full screen
- [x] 4.3 Sheet has Cancel/Done toolbar — Cancel reverts, Done keeps draft changes

## 5. Verify

- [x] 5.1 Test create flow: inline TextEditor works as before
- [x] 5.2 Test edit flow: preview card shows note text, tap opens sheet
- [x] 5.3 Test edit flow: sheet shows full notes, Cancel/Done work correctly
- [x] 5.4 Build passes clean
