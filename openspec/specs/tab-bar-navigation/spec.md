# tab-bar-navigation

## Purpose

Define the fixed root navigation: a four-tab bottom `TabView` for Today, Work, Personal, and More. The tab bar is a product invariant, not a place for user data.

## Requirements

### Requirement: Root navigation is a fixed 4-tab TabView

The app SHALL use a `TabView` with a bottom tab bar as its root navigation container. The tab bar SHALL display exactly four tabs, in this order:

| Tab | Purpose | Content |
|---|---|---|
| Today | Cross-domain attention | Overdue + tasks due today from both domains |
| Work | Work domain | Every task filed in Work |
| Personal | Personal domain | Every task filed in Personal |
| More | Management | Lists/projects per domain, Recently Completed, settings |

Each tab SHALL wrap its content in an independent `NavigationStack`.

#### Scenario: App launches to Today

- **WHEN** the app launches
- **THEN** Today SHALL be selected
- **AND** the Today task list SHALL be displayed

#### Scenario: Tapping tabs switches content

- **WHEN** the user taps Personal
- **THEN** Personal's content SHALL be displayed
- **AND** Today's navigation and scroll state SHALL be preserved

#### Scenario: Each tab has its own navigation stack

- **WHEN** the user opens a list detail from More
- **AND** switches to Work
- **THEN** Work SHALL show its root content
- **AND** More SHALL still be on the list detail when the user returns

### Requirement: No dynamic or user-created tabs

The tab bar SHALL remain exactly four tabs in every size class and on every device. It SHALL NOT append tabs for projects, lists, or user-created groups, and SHALL NOT remove tabs to make room for them.

The following SHALL NOT exist as root tabs: `Later`, `Tomorrow`, `Upcoming`, per-project tabs, per-domain duplicates of Work/Personal, and any user-created domain.

#### Scenario: Creating projects leaves the tab bar unchanged

- **WHEN** the user creates or restores any number of projects/lists
- **THEN** the tab bar SHALL still contain only Today, Work, Personal, and More

#### Scenario: Compact width does not change navigation

- **WHEN** the app runs on iPhone or in compact width
- **THEN** the same four tabs SHALL be shown
- **AND** no project SHALL be promoted into the tab bar

### Requirement: Today tab is cross-domain

The Today tab SHALL show incomplete tasks that are overdue or due today from both Work and Personal. It SHALL display a collapsible "Overdue" section at the top when overdue tasks exist, followed by today's tasks. Rows SHALL identify the owning domain/list when the view is unfiltered.

Today MAY offer an optional domain filter; the default SHALL be all domains. Today SHALL NOT split into separate time tabs.

#### Scenario: Overdue section appears

- **WHEN** an incomplete task from either domain is overdue
- **THEN** Today SHALL show an Overdue section above today's tasks
- **AND** tapping the section header SHALL collapse or expand it

#### Scenario: No overdue section

- **WHEN** no incomplete tasks are overdue
- **THEN** Today SHALL NOT show an Overdue section

#### Scenario: Today capture

- **WHEN** the user taps the floating + on Today
- **THEN** the editor SHALL open with due date set to today
- **AND** the default target SHALL be Work's Inbox bucket
- **AND** the user MAY choose a different domain/list in the editor

### Requirement: Work and Personal tabs show their domain

The Work and Personal tabs SHALL show every task filed in that domain, across all of the domain's projects/lists, independent of due date. Each tab SHALL:

- be titled `Work` or `Personal`
- show list/domain context on rows
- support list and board display modes
- allow filtering completed tasks
- create new tasks in that domain's Inbox bucket by default

The Work/Personal tabs SHALL NOT show only one project at a time. Selecting a project is a drill-down within the domain's management surface, not a root tab.

#### Scenario: Domain tab shows all its tasks

- **WHEN** the user opens Personal
- **THEN** tasks from every Personal list SHALL appear
- **AND** Work tasks SHALL NOT appear

#### Scenario: Domain capture lands in that domain

- **WHEN** the user taps + while viewing Work
- **THEN** the editor SHALL open with Work's Inbox selected by default
- **AND** the task SHALL NOT land in Personal

#### Scenario: Board column changes the list, not the domain

- **WHEN** the user drags a task from one board column to another in Work
- **THEN** the task's project/list SHALL change
- **AND** the task SHALL remain in Work

### Requirement: More holds management and secondary surfaces

The More tab SHALL be the only home for management and low-frequency surfaces:

- Work and Personal list/project management, grouped under their domain
- creating, renaming, deleting, and reordering lists inside a domain
- Recently Completed
- notifications, appearance, iCloud status, feedback, and app information

More SHALL NOT offer creation, renaming, deletion, or reordering of Work/Personal themselves. There SHALL be no "New Project" flow that creates a new `ReminderListGroup`.

#### Scenario: Managing lists in a domain

- **WHEN** the user opens More → Personal
- **THEN** the Personal lists SHALL be shown
- **AND** the user SHALL be able to add or manage lists within Personal
- **AND** no action SHALL create another domain

#### Scenario: Recently Completed

- **WHEN** the user opens More → Recently Completed
- **THEN** the Completed view SHALL be pushed within More's navigation stack

### Requirement: Consistent task surface

Tasks SHALL render with the same row component and editing flow in Today, Work, Personal, and list detail. A task's behavior SHALL NOT change because it was reached through a different domain/list path.

#### Scenario: Same row behavior everywhere

- **WHEN** the user views the same task from Today and from its Personal list
- **THEN** completion, editing, scheduling, and deletion SHALL behave identically

### Requirement: No sidebar or split-view root

The app SHALL NOT use `NavigationSplitView`, an inline sidebar, or a sidebar-backed smart-filter list as its root navigation. The root SHALL remain the four-tab `TabView`.

#### Scenario: No sidebar surface

- **WHEN** the app runs
- **THEN** the view hierarchy SHALL NOT contain a root `NavigationSplitView` or sidebar
- **AND** the root SHALL be the four-tab `TabView`
