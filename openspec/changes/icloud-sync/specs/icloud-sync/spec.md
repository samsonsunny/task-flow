## ADDED Requirements

### Requirement: All user data syncs across a user's devices
The system SHALL synchronize all persisted user data (tasks, lists, tags, and list groups) across a user's devices signed into the same iCloud account, using SwiftData's CloudKit mirroring against a single shared private container.

#### Scenario: Task created on one device appears on another
- **WHEN** the user creates or edits a task on device A while signed into iCloud
- **THEN** the task and its field values (title, description, due date, flags, completion state, priority, sort order, list membership, tags, parent/subtask links) appear on device B after CloudKit convergence

#### Scenario: Task deleted on one device is removed on another
- **WHEN** the user deletes a task on device A
- **THEN** that task is also deleted in the mirrored store on device B

#### Scenario: Relationship changes propagate
- **WHEN** the user moves a task between lists, changes its parent/subtask structure, assigns a group, or edits tags
- **THEN** the relationship change propagates to all synced devices

### Requirement: Sync is silent
The system SHALL enable CloudKit mirroring without adding any sync-specific user interface (banners, per-screen indicators, or a sync settings surface) in this release.

#### Scenario: No sync UI is shown
- **WHEN** a sync-enabled user opens the app
- **THEN** no iCloud/sync-specific controls or banners are displayed anywhere in the app

### Requirement: App remains usable when CloudKit is unavailable
The system SHALL degrade gracefully to a local-only store when CloudKit load or setup fails (no iCloud account, entitlements misconfigured, CloudKit schema incompatibility), instead of crashing at launch.

#### Scenario: CloudKit container fails to load
- **WHEN** the app cannot create the CloudKit-backed model container at launch
- **THEN** the app launches against a local-only store and existing local user data remains readable and editable

#### Scenario: User is not signed into iCloud
- **WHEN** the app launches on a device without an iCloud account
- **THEN** the app continues to function as a local-only app without data loss or crash

### Requirement: Existing local data migrates into the synced store
The system SHALL allow a pre-sync user's existing local store to load under the CloudKit-backed configuration so that their data becomes available to other devices without manual export or re-entry.

#### Scenario: Existing local store opens with sync enabled
- **WHEN** a user who previously used the local-only app upgrades to the sync-enabled version
- **THEN** their existing tasks, lists, tags, and groups load and sync to CloudKit without destructive rewriting

### Requirement: Inbox list remains unique across devices
The system SHALL prevent duplicate "Inbox" lists from persisting when multiple devices create or reference the default list concurrently.

#### Scenario: Second device seeds Inbox before cloud copy arrives
- **WHEN** a new device creates an "Inbox" list while the synced Inbox from another device has not yet arrived
- **THEN** the duplicates are reconciled into a single Inbox list without losing tasks

### Requirement: Views refresh after remote merges
The system SHALL recompute ViewModel-derived state when data changes arrive from CloudKit, not only when the user mutates data locally.

#### Scenario: Remote edit appears without local interaction
- **WHEN** device B receives a property-only change (e.g., title edit, flags, due date) made on device A
- **THEN** the affected screens' ViewModels recompute and the UI reflects the new values without the user performing a local mutation

#### Scenario: Local completion toggle persists
- **WHEN** the user toggles a task's completed state
- **THEN** the change is saved to the model context and propagates to other devices

### Requirement: Schema remains CloudKit-compatible
The system SHALL keep the persisted models compatible with CloudKit mirroring at all times: every attribute optional or with a property-level default value, every relationship optional, no unique constraints, and no `.deny` delete rule.

#### Scenario: New schema versions preserve compatibility
- **WHEN** the model schema is evolved in future releases
- **THEN** new attributes have defaults or are optional, new or existing relationships remain optional, and no unique constraints are introduced

### Requirement: Sort-order backfill does not clobber synced ordering
The system SHALL make legacy sort-order backfill data-gated rather than flag-gated, so that a second device's first launch does not rewrite sort orders that were synced from another device.

#### Scenario: Second device backfill is skipped
- **WHEN** a second device launches with synced tasks that already have sort orders
- **THEN** the backfill does not rewrite sort orders assigned on the first device

#### Scenario: Backfill only repairs missing values
- **WHEN** any task lacks a sort order
- **THEN** the backfill assigns sort orders only to those tasks, leaving existing values untouched