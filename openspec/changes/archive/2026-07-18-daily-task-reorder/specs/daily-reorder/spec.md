# Daily Task Reorder

## Requirement: Drag-to-reorder in Today view

The user SHALL be able to reorder root tasks in the Today view by long-pressing and dragging. The order SHALL persist across app restarts using UserDefaults.

#### Scenario: Drag reorders root tasks in Today

1. Given the Today view shows root tasks [A, B, C]
2. When the user drags B above A
3. Then the Today view shows [B, A, C]
4. And the order persists after app restart

#### Scenario: Children follow parent

1. Given the Today view shows root task A with subtasks A.1 and A.2
2. When the user drags A above another root task
3. Then A.1 and A.2 remain nested under A

## Requirement: Drag-to-reorder in Tomorrow view

The user SHALL be able to reorder root tasks in the Tomorrow view by long-pressing and dragging. The order SHALL persist across app restarts using UserDefaults.

#### Scenario: Drag reorders root tasks in Tomorrow

1. Given the Tomorrow view shows root tasks [D, E]
2. When the user drags E above D
3. Then the Tomorrow view shows [E, D]

## Requirement: Overdue section independent ordering

The Overdue section in the Today view SHALL have its own independent ordering, separate from Today's main tasks.

#### Scenario: Overdue and Today tasks have separate order

1. Given the Today view shows overdue tasks [O1, O2] and today tasks [T1, T2]
2. When the user reorders overdue tasks to [O2, O1]
3. Then today tasks remain in their existing order [T1, T2]

## Requirement: New tasks appear at end

Tasks without a stored order SHALL appear at the end of the list in their default date-sorted order.

#### Scenario: New task appears at bottom

1. Given the Today view shows reordered tasks [B, A, C]
2. When a new task D is created with today's due date
3. Then D appears after C (at the bottom)

## Requirement: List view order unaffected

Reordering in Today/Tomorrow views SHALL NOT affect the task's `sortOrder` property used in List views.

#### Scenario: List view preserves original order

1. Given task "Buy Milk" has `sortOrder` "m" in the "Shopping" list
2. When the user drags "Buy Milk" to the top of Today view
3. Then "Buy Milk" still appears at position "m" in the "Shopping" list
