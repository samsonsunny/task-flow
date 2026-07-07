---
name: ralph-loop
description: Run the Ralph autonomous coding loop against a PRD JSON file in this project
license: MIT
compatibility: opencode
metadata:
  audience: developer
  workflow: automation
---

## What this does

Runs Ralph's outer loop (`.agents/ralph/loop.sh`) — an autonomous coding agent that iterates through stories in a PRD JSON file. Each iteration selects the next open story, invokes an AI agent to implement it, checks for a completion signal, and repeats until all stories are done.

## When to use

Use when the user says "run ralph", "ralph loop", "start ralph", or wants to resume autonomous story implementation. Do NOT use this for manual edits or single-file changes.

Do NOT run the loop in the background — the user should see the output.

## How it works

1. The loop script is at `.agents/ralph/loop.sh`
2. PRD files are JSON files in `.agents/tasks/` (e.g. `mvvm-schedule-picker.json`)
3. The script needs `PRD_PATH` set to the target PRD file
4. It executes the agent CLI defined in `.agents/ralph/agents.sh` (default: codex)
5. Each iteration runs one story, committing changes when done
6. Look for the `<promise>COMPLETE</promise>` signal in the output to confirm a story finished

## Steps for the agent

1. **List available PRDs** — glob `.agents/tasks/*.json`
2. **Check status** — for each PRD, run `python3 -c "import json,sys; d=json.load(open(sys.argv[1])); stories=d.get('stories',[]); remaining=[s for s in stories if s.get('status','open').strip().lower()!='done']; print(f'{len(remaining)} remaining')" <prd_path>` to see how many stories remain
3. **Present options** — show the user which PRDs have remaining stories and ask which to target
4. **Run the loop** — `PRD_PATH=<selected_prd> ./.agents/ralph/loop.sh` from the project root
5. **Report results** — tell the user what completed and what happened

## Notes

- The loop can take many minutes per iteration — let it run
- If interrupted, stories marked `in_progress` may need manual reset to `open` in the PRD JSON
- The `.ralph/` directory accumulates run logs and progress; do not commit `.ralph/` contents
