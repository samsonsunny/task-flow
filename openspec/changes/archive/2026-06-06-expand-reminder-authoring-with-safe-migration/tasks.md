## 1. Persistence Foundation

- [x] 1.1 Introduce a versioned SwiftData schema and migration plan for reminder persistence
- [x] 1.2 Expand the persisted reminder model with additive authoring fields and safe defaults for migrated rows
- [x] 1.3 Add companion persistence structures for tags, list assignment, and richer metadata where direct root fields are not sufficient

## 2. Authoring Draft And Save Logic

- [x] 2.1 Create a shared reminder draft model for create and edit flows with dirty-state tracking
- [x] 2.2 Implement save enablement, empty-reminder blocking, and discard confirmation behavior from the authoring spec
- [x] 2.3 Map draft values to and from persisted reminder entities, including default list and priority rules

## 3. Authoring UI Expansion

- [x] 3.1 Build the reminder create surface with title, notes, URL, list, tags, flag, priority, contact, image, and schedule entry points
- [x] 3.2 Add reminder edit flow parity so existing reminders can be reopened and updated through the same authoring rules
- [x] 3.3 Integrate tag uniqueness handling, URL clearing, and other field-level affordances required by the authoring spec

## 4. Migration Verification

- [x] 4.1 Add fixture coverage for legacy reminders migrating into the expanded schema without data loss
- [x] 4.2 Add unit and UI coverage for authoring save/discard rules, default metadata behavior, and migrated reminder editing
- [x] 4.3 Document known open issues or product decisions needed before implementation, especially malformed URL validation and attachment/contact persistence details
