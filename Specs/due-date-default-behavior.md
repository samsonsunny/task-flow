# Due Date Defaults

*Issue:* Tasks created without an explicit due date currently fall back to `Date()` when displayed, so they appear in the *Today* bucket even though the user never selected today.

*Action:* Revisit the `TaskItem.safeDueDate` fallback and task sectioning logic so that unscheduled tasks land in a neutral "Someday"/"Later" area instead of defaulting to today. Also update any UI copy that reads a hard-coded date when none exists.

*Status:* Backlogged per PM request; revisit when working on due-date UX polish.
