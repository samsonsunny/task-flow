# Move to Top / Bottom

## Requirement: Move to Top action

The user SHALL be able to move a task to the top of its ordering context via a single tap in the context menu.

### Scenario: Move root task to top of list

1. Given a list with root tasks [A, B, C] (in that order)
2. When the user long-presses C and taps "Top"
3. Then the list shows [C, A, B]
4. And the order persists across app restarts

### Scenario: Move child task to top of siblings

1. Given root task A has children [X, Y, Z]
2. When the user long-presses Z and taps "Top"
3. Then A's children show [Z, X, Y]
4. And Z remains a child of A

## Requirement: Move to Bottom action

The user SHALL be able to move a task to the bottom of its ordering context via a single tap in the context menu.

### Scenario: Move root task to bottom of list

1. Given a list with root tasks [A, B, C]
2. When the user long-presses A and taps "Bottom"
3. Then the list shows [B, C, A]

### Scenario: Move child task to bottom of siblings

1. Given root task A has children [X, Y, Z]
2. When the user long-presses X and taps "Bottom"
3. Then A's children show [Y, Z, X]

## Requirement: Hide when single task

The "Top" and "Bottom" actions SHALL NOT appear when the task is the only one in its ordering context.

### Scenario: Single root task hides actions

1. Given a list with only one root task A
2. When the user long-presses A
3. Then "Top" and "Bottom" do not appear in the context menu

### Scenario: Single child hides actions

1. Given root task A has only one child X
2. When the user long-presses X
3. Then "Top" and "Bottom" do not appear in the context menu

## Requirement: List view scope

The "Top" and "Bottom" actions SHALL only appear in list views (DetailView), not in daily views (Today/Tomorrow).

### Scenario: Actions hidden in Today view

1. Given the user is in the Today view
2. When the user long-presses a task
3. Then "Top" and "Bottom" do not appear in the context menu
