# area-locking

## Purpose

Define the fixed two-area model: the `isLocked` flag, identification of the Work and Personal areas, the recurring reconciler that merges extra areas into Work, the absence of area CRUD UI, and cross-area task moves.

## ADDED Requirements

### Requirement: Areas carry a persisted lock flag

`ReminderListGroup` SHALL have an `isLocked: Bool` property defaulting to `false`. The flag SHALL be persisted in the latest schema version so it survives app restarts and CloudKit sync. A locked area SHALL NOT be renamable, deletable, reorderable, or removable by any code path, and its name SHALL be the canonical name for its role.

The lock SHALL be a persisted data property rather than a name comparison, so that lock state is exact and does not depend on localized or user-edited names.

#### Scenario: Default is unlocked
- **WHEN** a `ReminderListGroup` is created without specifying a lock
- **THEN** its `isLocked` value SHALL be `false`

#### Scenario: Lock state survives relaunch
- **WHEN** an area is locked and the app is relaunched
- **THEN** the area SHALL still report `isLocked == true`

#### Scenario: Lock state is not derived from the name
- **WHEN** an area's name is changed by any means while locked
- **THEN** the reconciler SHALL restore the canonical name for that area's role
- **AND** the area SHALL remain locked

### Requirement: The store contains exactly two locked areas

After the reconciler runs, the store SHALL contain exactly two `ReminderListGroup` objects, one named "Work" and one named "Personal", both with `isLocked == true`, and no unlocked groups.

The Work area SHALL be identified, in order, by: a group whose name is "Work"; otherwise the group with the lowest `sortOrder`, breaking ties by earliest `createdAt`; otherwise a newly seeded group. The Personal area SHALL be identified by a group named "Personal" other than the Work group, otherwise a newly seeded group.

#### Scenario: Named Work and Personal are adopted
- **WHEN** the store contains groups named "Work" and "Personal"
- **THEN** both SHALL be marked locked
- **AND** no new area SHALL be seeded

#### Scenario: Work is identified positionally when unnamed
- **WHEN** the store contains a group named "Job" with the lowest `sortOrder` and no group named "Work"
- **THEN** that group SHALL be adopted as the Work area
- **AND** it SHALL be renamed to "Work"

#### Scenario: Empty store seeds both areas
- **WHEN** the store contains no groups
- **THEN** the reconciler SHALL seed a "Work" area and a "Personal" area
- **AND** both SHALL be marked locked
- **AND** each SHALL own its own Inbox bucket

#### Scenario: Only Work exists
- **WHEN** the store contains exactly one group
- **THEN** that group SHALL be locked as Work
- **AND** a "Personal" area SHALL be seeded with its own Inbox bucket

#### Scenario: Store ends with exactly two groups
- **WHEN** the reconciler finishes
- **THEN** the store SHALL contain exactly two groups
- **AND** both SHALL have `isLocked == true`

### Requirement: Extra areas are merged into Work

For each group that is neither the Work area nor the Personal area, the reconciler SHALL, in order: (1) if the extra group has an Inbox bucket that is not Work's bucket, set every task in that bucket's `reminderList` to Work's Inbox bucket, then delete the emptied bucket; (2) set the `group` of each remaining list of the extra group to Work and set its `sortOrder` to `nil`; (3) delete the extra group, which SHALL by then contain no lists; (4) backfill list sort orders, ordering each group's bucket first and then by name and `createdAt`.

The reconciler SHALL NOT create, delete, or modify any `TaskItem` property; it SHALL only reassign the `reminderList` pointer of tasks in a foreign bucket. The reconciler SHALL persist its changes in a single save, and SHALL roll back and leave the store unchanged if the save throws.

The merge SHALL NOT surface any banner, alert, or toast.

#### Scenario: Extra area's lists move to Work
- **WHEN** the store contains a third group "Side Projects" with lists "Web" and "Copy"
- **THEN** both lists SHALL have their `group` set to Work
- **AND** the "Side Projects" group SHALL be deleted

#### Scenario: Extra area's bucket tasks move to Work's bucket
- **WHEN** the "Side Projects" group has an Inbox bucket containing 2 tasks
- **THEN** both tasks SHALL have their `reminderList` set to Work's Inbox bucket
- **AND** the "Side Projects" Inbox bucket SHALL be deleted
- **AND** no task SHALL have been created, deleted, or otherwise modified

#### Scenario: Merged lists keep no stale sort order
- **WHEN** lists are merged into Work
- **THEN** each merged list SHALL have `sortOrder == nil` before backfill
- **AND** after backfill every list SHALL have a non-nil `sortOrder` ordering Work's bucket first

#### Scenario: Empty extra area is deleted
- **WHEN** the store contains a third group with no lists
- **THEN** that group SHALL be deleted

#### Scenario: Extra area's tasks survive the merge
- **WHEN** an extra area holds tasks across several of its lists
- **THEN** every one of those tasks SHALL still exist after the merge
- **AND** each SHALL be present in a Work list
- **AND** each SHALL retain its title, dates, completion state, notes, and priority

#### Scenario: Merge is silent
- **WHEN** the merge occurs
- **THEN** no banner, alert, toast, or other interruption SHALL be presented

#### Scenario: Merge is a single atomic save
- **WHEN** the merge runs
- **THEN** changes SHALL be persisted in one save
- **AND** if that save throws, the context SHALL be rolled back and the store SHALL be left unchanged

#### Scenario: Merge is idempotent
- **WHEN** the reconciler runs a second time against an already-merged store
- **THEN** it SHALL perform no merge
- **AND** it SHALL leave the two locked areas unchanged

### Requirement: The locked-area reconciler runs on every launch

The reconciler SHALL run on every app launch, before any view reads area state. It SHALL NOT be guarded by a one-time migration flag, so that a group synced down from another device running an older build is merged on the next launch. The reconciler SHALL be idempotent.

#### Scenario: Reconciler runs before the first view reads areas
- **WHEN** the app launches
- **THEN** the reconciler SHALL have completed before the root view's data is consumed
- **AND** no view SHALL observe more than two unlocked areas

#### Scenario: Stale synced area is merged on next launch
- **WHEN** another device running an older build creates and syncs a third area
- **THEN** on the next launch on this device the third area's lists SHALL be merged into Work

#### Scenario: No UserDefaults flag gates the reconciler
- **WHEN** the user relaunches the app
- **THEN** the reconciler SHALL execute again
- **AND** it SHALL rely on no persisted "already migrated" marker

### Requirement: Area creation and area editing UI do not exist

The app SHALL NOT provide any control for creating a group, renaming a group, deleting a group, reordering groups, moving a list into a different group, or ungrouping a list. All group-creation surfaces SHALL be removed: the list row's "Create New Group" context-menu item, the "New Group…" entry in any list-association submenu, the group-creation sheet, the mini-sheet used for on-the-fly group creation, and the group picker inside list creation.

`deleteGroup` SHALL be removed, because it deletes every list and every task in an area and has no guard against locked areas.

#### Scenario: No create-group control exists
- **WHEN** the user views Home, a list detail, list creation, or any context menu
- **THEN** no "Create New Group", "New Group…", or equivalent group-creation control SHALL be offered

#### Scenario: No rename-group control exists
- **WHEN** the user opens the context menu on any area
- **THEN** no "Rename" option SHALL be offered for the area

#### Scenario: No delete-group control exists
- **WHEN** the user opens the context menu on any area
- **THEN** no "Delete" option SHALL be offered for the area
- **AND** no area's lists or tasks SHALL be removable as a group operation

#### Scenario: No move-list-to-group control exists
- **WHEN** the user opens the context menu on a list row
- **THEN** no "Move to Group" submenu SHALL be offered
- **AND** no ungrouping option SHALL be offered

#### Scenario: No group reorder affordance exists
- **WHEN** the user views Home
- **THEN** areas SHALL NOT be draggable
- **AND** no area reorder control SHALL be present

#### Scenario: List creation has no group picker
- **WHEN** the user opens the list creation sheet
- **THEN** the sheet SHALL contain a name field only
- **AND** the new list SHALL be created in the selected area

### Requirement: Lists inside locked areas remain editable

A list inside a locked area SHALL still be renameable, deletable, and reorderable, and the area's Inbox bucket SHALL remain protected by pointer (`list == list.group?.defaultList`). Operations that would alter a locked area's identity SHALL be refused.

#### Scenario: Custom list inside a locked area is renameable
- **WHEN** the user renames a custom list inside Work
- **THEN** the list SHALL be renamed
- **AND** the Work area SHALL remain locked and named "Work"

#### Scenario: Area bucket stays protected
- **WHEN** the user opens the context menu on an area's Inbox bucket
- **THEN** no "Rename", "Delete", or "Move to Group" option SHALL be offered

#### Scenario: List operations cannot unlock an area
- **WHEN** any list operation is performed inside a locked area
- **THEN** the area's `isLocked` value SHALL remain `true`

### Requirement: Tasks can be moved between areas

A task SHALL be movable to any list in any area, including across the Work and Personal boundary. Area membership SHALL be a property of the destination list, not of the task, so a cross-area move SHALL be performed solely by reassigning the task's `reminderList`. Moving a task between areas SHALL require no schema change and SHALL NOT alter any other task property.

#### Scenario: Task moves from Work to Personal
- **WHEN** the user assigns a Work task to a Personal list
- **THEN** the task's `reminderList` SHALL be set to that Personal list
- **AND** the task SHALL appear in Personal's sections on Home
- **AND** it SHALL no longer appear in Work's sections

#### Scenario: Task moves from Personal to Work
- **WHEN** the user assigns a Personal task to a Work list
- **THEN** the task SHALL appear in the Work area only

#### Scenario: Cross-area move preserves task data
- **WHEN** a task with a due date, notes, priority, and subtasks is moved across areas
- **THEN** all of those properties SHALL be unchanged
- **AND** only its `reminderList` SHALL differ

#### Scenario: Task moved into an area's bucket
- **WHEN** the user moves a task to an area's Inbox bucket
- **THEN** the task SHALL appear in that area's pinned Inbox section

#### Scenario: Bulk move may cross areas
- **WHEN** the user selects tasks in one area and bulk-moves them to a list in the other area
- **THEN** every selected task SHALL be moved to that list
