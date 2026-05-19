---
name: orient
description: >
  Session-start briefing. Loads goals, due reminders, queue status, and recent
  session handoff notes to eliminate cold starts. Run at the beginning of any
  work session to know where you are and what needs attention.
when_to_use: >
  "orient", "start session", "what's going on", "catch me up",
  "what was I doing", "morning briefing", "session start"
allowed-tools: Bash Read Grep Glob
---

# orient -- Session Start Briefing

Load your current state so you never start a session cold. Surfaces what matters
NOW: active goals, due reminders, queue status, and the last session's handoff.

## When to Use

- Beginning of any work session
- After a break or context switch
- When you've forgotten what you were doing
- "What should I be thinking about right now?"

## When NOT to Use

- Mid-session (you already have context)
- Looking for specific knowledge (use `/retrieve`)
- Adding tasks (use `/queue add`)

---

## Procedure

### Step 1: Load Config

Read `.claude/obsidian-knowledge-management.local.md` frontmatter to get `vault_path`.
Read `{vault_path}/.vault-config.md` to get `self_dir`, `ops_dir`, and `knowledge_vaults`.

If either file is missing, tell the user to run `/setup` first and stop.

### Step 2: Load Self State

Read `{vault_path}/{self_dir}/goals.md` in full.

Present:
```
## Active Threads
{content from Active Threads section}
```

If empty, note: "No active threads. Use `/queue add` to get started."

### Step 3: Check Reminders

Read `{vault_path}/{ops_dir}/reminders.md`.

Filter for items where the date is today or earlier (overdue):

```bash
TODAY=$(date +%Y-%m-%d)
grep -E "^- \[ \]" "{vault_path}/{ops_dir}/reminders.md" | while read line; do
  DATE=$(echo "$line" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
  if [[ "$DATE" <= "$TODAY" ]]; then
    echo "$line"
  fi
done
```

Present:
```
## Due Reminders
{list of due/overdue items, or "None due today."}
```

### Step 4: Queue Status

Count items in `{vault_path}/{ops_dir}/queue/`:

```bash
QUEUE_DIR="{vault_path}/{ops_dir}/queue"
if [ -d "$QUEUE_DIR" ]; then
  TOTAL=$(find "$QUEUE_DIR" -name "*.md" | wc -l | tr -d ' ')
  BLOCKED=$(grep -rl "status: blocked" "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  READY=$(grep -rl "status: ready" "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  IN_PROGRESS=$(grep -rl "status: in-progress" "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  echo "Total: $TOTAL | Ready: $READY | In Progress: $IN_PROGRESS | Blocked: $BLOCKED"
fi
```

Present:
```
## Queue
{total} tasks — {ready} ready, {in_progress} in progress, {blocked} blocked
{if in_progress > 0: list the in-progress task titles}
```

### Step 5: Last Session Handoff

Find the most recent session file:

```bash
SESSIONS_DIR="{vault_path}/{ops_dir}/sessions"
LATEST=$(ls -t "$SESSIONS_DIR"/*.md 2>/dev/null | head -1)
```

If found, read and present the `## Handoff` section (or full file if short).

Present:
```
## Last Session ({date})
{handoff content — what was in progress, what's next}
```

If no session files exist, note: "No previous sessions recorded."

### Step 6: Inbox Check

Quick count of items in inbox:

```bash
INBOX_COUNT=$(find "{vault_path}/inbox" -name "*.md" | wc -l | tr -d ' ')
```

If > 0:
```
## Inbox
{count} items waiting to be processed. Run `/maintain inbox` when ready.
```

---

## Output Format

Combine all sections into a single briefing:

```markdown
# Session Briefing — {YYYY-MM-DD HH:MM}

## Active Threads
{from goals.md}

## Due Reminders
{due/overdue items or "None due today."}

## Queue
{summary line}
{in-progress items if any}

## Last Session ({date})
{handoff summary}

## Inbox
{count} items waiting.

---
Ready. What would you like to focus on?
```

Keep it scannable. No walls of text. If a section is empty, show one line
acknowledging it rather than omitting the heading (prevents confusion about
whether it was checked).

---

## Edge Cases

- **First ever session** (no goals, no sessions, empty queue): Present a welcoming "fresh start" message and suggest `/queue add` for their first task.
- **Many overdue reminders** (>5): Summarise count and show top 5 by date. Suggest reviewing with `/queue` or clearing stale ones.
- **Very long goals file**: Show only the Active Threads section, not Deferred or Completed.
- **Corrupted or missing frontmatter**: Warn which file has issues, continue with what's readable.
