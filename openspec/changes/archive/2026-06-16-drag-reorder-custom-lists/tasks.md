## 1. Data Model

- [x] 1.1 Add `sortOrder: String?` attribute to `TaskFlowSchemaV3.TaskItem`
- [x] 1.2 Create `TaskFlowSchemaV3` versioned schema with `TaskItem`, `ReminderList`, `ReminderTag`
- [x] 1.3 Add V2→V3 lightweight migration stage to `TaskFlowMigrationPlan`
- [x] 1.4 Update `ModelContainer` init to use `TaskFlowSchemaV3`
- [x] 1.5 Update `typealias TaskItem` to point to V3

## 2. Midpoint Algorithm

- [x] 2.1 Implement `midpoint(between:and:)` utility function
- [x] 2.2 Implement `widen(_:)` fallback for adjacency exhaustion
- [x] 2.3 Unit test midpoint function with representative edge cases

## 3. Migration Backfill

- [x] 3.1 Write backfill that assigns sortOrders to existing tasks in each custom list based on `createdAt` order
- [x] 3.2 Ensure smart segment tasks remain unmodified (no sortOrder assignment needed)

## 4. ListDetailView Reordering

- [x] 4.1 Change `@Query` sort from `createdAt` reverse to `sortOrder` forward
- [x] 4.2 Computed property falls back to `createdAt` descending for tasks with nil `sortOrder` (via query default)
- [x] 4.3 Add `.onMove` modifier to `ForEach` in `ListDetailView`
- [x] 4.4 Implement `moveTasks(fromOffsets:toOffset:)` handler using midpoint algorithm
- [x] 4.5 Handle multi-drag by chaining midpoints for each dragged item

## 5. New Task Creation

- [x] 5.1 Assign `sortOrder` when creating tasks via `ReminderEditorView.saveReminder()`
- [x] 5.2 Initial sortOrder uses `midpoint(nil, lastTask.sortOrder)` — always appends at end

## 6. Verify

- [x] 6.1 Smart segments have no reorder affordance — `ListDetailView` is the only view with `.onMove`
- [x] 6.2 Build succeeds, tests pass
- [x] 6.3 New tasks appear at end via `assignInitialSortOrder`
