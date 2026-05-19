---
name: queue
description: >
  Task pipeline management. Add tasks, decompose them into steps, advance status,
  and review the queue. Tasks are markdown files in ops/queue/ with structured
  frontmatter for energy, size, and priority metadata.
when_to_use: >
  "queue", "add task", "new task", "decompose", "break down",
  "task status", "mark done", "show tasks", "what's in the queue"
argument-hint: "add|list|advance|decompose|done|drop [task-or-description]"
allowed-tools: Bash Read Write Edit Grep Glob
---

# queue -- Task Pipeline Management

Manage your task pipeline. Tasks live as individual markdown files in `ops/queue/`
with structured frontmatter that enables energy-aware prioritisation.

## When to Use

- Adding a new task or idea to work on
- Breaking a large task into smaller steps
- Changing task status (ready → in-progress → done)
- Reviewing what's in the pipeline
- Dropping tasks that are no longer relevant

## When NOT to Use

- Choosing what to do next (use `/next`)
- Session-level orientation (use `/orient`)
- Time-bound reminders (add directly to `ops/reminders.md`)

---

## Commands

### `queue add "description"`

Create a new task file in the queue.

#### Procedure:

1. Generate filename: `{YYYY-MM-DD}-{slug}.md` where slug is 3-5 words from description
2. Interview (quick — 3 questions max, skipped if provided as flags `--energy`, `--size`, `--priority`):
   - **Energy required?** (low / medium / high) — "Could you do this tired?"
   - **Size?** (quick: <15min / short: 15-45min / full: 1h+) — "How long roughly?"
   - **Priority?** (1-5, default 3) — or infer from context
3. Auto-detect `goal` alignment by matching description against `self/goals.md` active threads
4. Write the task file

```bash
QUEUE_DIR="{vault_path}/{ops_dir}/queue"
FILENAME="$(date +%Y-%m-%d)-{slug}.md"
```

Write `{queue_dir}/{filename}`:

```markdown
---
title: {description}
created: {YYYY-MM-DD}
status: ready
energy: {low|medium|high}
size: {quick|short|full}
priority: {1-5}
goal: "{matched active thread or empty}"
tags: []
---

# {Description}

{If user provided more context, include it here. Otherwise leave for later.}

## Steps

- [ ] {first obvious step, or "Define first step"}

## Context

<!-- Links to relevant notes or domain knowledge -->
```

#### Quick-add shorthand:

If the user provides energy/size inline, skip the interview:

- `/queue add "Fix the login bug" --energy low --size quick`
- `/queue add "Design new caching layer" --energy high --size full --priority 1`

---

### `queue list`

Show all tasks grouped by status.

```bash
QUEUE_DIR="{vault_path}/{ops_dir}/queue"
```

For each `.md` file in the queue directory, extract frontmatter fields.

**Output format:**

```markdown
# Queue ({total} tasks)

## In Progress ({count})
| Task | Energy | Size | Priority | Age |
|------|--------|------|----------|-----|
| {title} | {energy} | {size} | {priority} | {days since created} |

## Ready ({count})
| Task | Energy | Size | Priority | Age |
|------|--------|------|----------|-----|
| ... sorted by priority then age ... |

## Blocked ({count})
| Task | Blocked By | Since |
|------|-----------|-------|
| {title} | {reason} | {date} |

## Done (last 7 days, {count})
| Task | Completed |
|------|-----------|
| {title} | {date} |
```

Tasks older than 14 days in "done" status are candidates for archiving (mention this if any exist).

---

### `queue advance "task-name"`

Move a task to the next status in the pipeline:

```
ready → in-progress → done
```

1. Find the task file (fuzzy match on title or filename)
2. Update `status` in frontmatter
3. If advancing to `done`:
   - Add `completed: {YYYY-MM-DD}` to frontmatter
   - Check if the task's `goal` maps to a goals.md thread — if so, note the progress
4. Confirm: "{title} is now {new_status}."

#### Special transitions:

- `queue block "task" "reason"` — sets status to `blocked`, adds `blocked_by` field
- `queue unblock "task"` — sets status back to `ready`, removes `blocked_by`

---

### `queue decompose "task-name"`

Break a task into smaller sub-tasks. Essential for ADHD — large tasks are
paralysing, small steps are achievable.

#### Procedure:

1. Read the task file
2. Discuss with the user: "What are the actual steps to get this done?"
3. For each sub-step that's substantial enough to be its own task:
   - Create a new task file with:
     - Lower energy/size than the parent
     - Same goal and tags as parent
     - `parent: "[[{parent-filename}]]"` in frontmatter
   - Add the step to the parent's `## Steps` section as a `[[link]]`
4. Mark the parent as a "meta-task" by adding `type: epic` to its frontmatter
5. Parent status stays `ready` until all children are done

**Output after decomposition:**

```markdown
Decomposed "{parent title}" into {N} sub-tasks:

1. {sub-task title} [{energy}/{size}]
2. {sub-task title} [{energy}/{size}]
3. ...

The parent task now tracks these as steps. `/next` will surface
individual sub-tasks instead of the overwhelming parent.
```

---

### `queue done "task-name"`

Shorthand for `queue advance` to done status. Also:

1. Marks task as `status: done`, adds `completed` date
2. Checks all steps in `## Steps` — warns if unchecked items remain
3. Celebrates briefly (one line, not patronising)

---

### `queue drop "task-name"`

Remove a task that's no longer relevant.

1. Find the task file
2. Confirm: "Drop '{title}'? This moves it to done with `dropped: true`. (yes/no)"
3. Add `dropped: true` and `status: done` to frontmatter
4. Don't delete the file — dropped tasks are still searchable history

---

### `queue clean`

Archive old completed/dropped tasks.

1. Find all tasks with `status: done` older than 14 days
2. Move them to `{ops_dir}/queue/archive/` (create if needed)
3. Report: "Archived {N} completed tasks."

---

## Design Principles

1. **Low friction to add** — `/queue add "thing"` should take <30 seconds including the energy/size questions.
2. **Decompose over estimate** — when a task feels too big, break it down rather than guessing the size.
3. **One file per task** — enables Obsidian linking, grep, and individual task context.
4. **Metadata enables `/next`** — energy and size fields are what make smart recommendations possible.
5. **Never lose anything** — done/dropped tasks are archived, not deleted. History matters.
6. **No due dates by default** — due dates create anxiety. Use `ops/reminders.md` for time-bound items. Tasks are prioritised by importance, not urgency.

---

## Edge Cases

- **Fuzzy title matching**: When a command references a task by name, search filenames with `grep -il "{query}" {queue_dir}/*.md`, then fall back to `grep -l "title:.*{query}" {queue_dir}/*.md` (case-insensitive). If ambiguous (multiple matches), present options and ask user to pick.
- **Empty queue**: Respond helpfully — "Queue is empty. What's on your mind? I'll help you capture it."
- **Too many tasks (>20 ready)**: Suggest a triage session — "You have {N} ready tasks. Want to do a quick priority pass? We can drop, defer, or decompose."
- **Conflicting priorities**: If multiple priority-1 tasks exist, surface this during `/next` as a decision point, not here.
