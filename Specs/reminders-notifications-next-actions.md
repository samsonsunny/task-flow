# Reminders & Notifications — Next Actions

This note captures follow-up opportunities after the initial reminder implementation.

## Goals
- Keep TaskFlow a task app first, while making reminders feel like a quiet, helpful layer.
- Favor simple defaults, with optional control for power users.

## Current Baseline (Simple)
- Daily review reminder at 9:00 AM local time.
- Per-task reminder time optional in Task Detail.
- Due date fallback reminder at 9:00 AM if no reminder time is set.
- Tasks without a date show “No date” and do not trigger reminders.

## Next Actions (Recommended Order)
1. Daily review time preference
- Add a time picker in Settings for daily review reminder.
- Persist via `AppStorage` and reschedule on change.

2. Overdue nudge
- Send a single next-morning reminder for overdue tasks at the daily review time.
- Avoid repeated daily nagging unless the user opts in.

3. Inline reminder controls
- Add a compact “Remind me” chip in the inline add row.
- Allow a quick time selection (e.g., Today 9 AM, Tomorrow 9 AM, Tonight 6 PM).

4. Quiet hours
- Allow a configurable quiet window (e.g., 9 PM–7 AM) and defer reminders.
- Respect system Focus and notification summary when possible.

5. Reminder audit + recovery
- A lightweight in-app list of scheduled reminders for debugging and user trust.
- Show last scheduled time and next fire time in Task Detail.

6. Notification permission UX
- Add a soft prompt explaining the benefit before requesting permissions.
- If denied, show a one-tap path to iOS Settings.

7. Repeating reminders (lightweight)
- Allow daily or weekly repeat for a task.
- Always show the next occurrence and allow pausing.

8. Completion sync
- Cancel reminders immediately when a task is completed or deleted.
- On app launch, reschedule reminders for all active tasks.

## Near-Term Focus (Grouped)
UX
1. Inline reminder controls
2. Reminder audit + recovery
3. Notification permission UX

Scheduling Logic
1. Daily review time preference
2. Overdue nudge
3. Quiet hours
4. Repeating reminders
5. Completion sync

## Technical Notes
- Add a background reschedule pass on launch or scene activation.
- Add unit tests for reminder date resolution rules.
- Record simple analytics events (optional): reminder scheduled, delivered, acted-on.

## Open Questions
- Should daily review include a summary notification body (e.g., “3 tasks due today”)?
- Should overdue nudges be opt-in or default on?
- Do we want badges to reflect overdue count or today’s count?
