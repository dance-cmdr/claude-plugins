---
name: wrap
description: >
  Session-end ritual. Captures what happened, updates goals, advances tasks,
  records a handoff note for the next session, and optionally commits state.
  Prevents attention residue by creating clean closure.
when_to_use: >
  "wrap", "wrap up", "end session", "I'm done for now", "session end",
  "save state", "handoff", "signing off"
allowed-tools: Bash Read Write Edit Grep Glob
---

# wrap -- Session End Ritual

Create clean closure at the end of a work session. Captures progress, updates
persistent state, and writes a handoff note so your next session starts warm.

## When to Use

- End of a work session (any length)
- Before a context switch to different work
- When you're about to lose focus and want to save state
- "I need to stop but I don't want to lose where I am"

## When NOT to Use

- Mid-session check-in (just keep working)
- Starting a session (use `/orient`)
- Adding new tasks (use `/queue add`)

---

## Procedure

### Step 1: Load Config

Read `.claude/obsidian-knowledge-management.local.md` to get `vault_path` and `auto_commit`.
Read `{vault_path}/.vault-config.md` to get `self_dir`, `ops_dir`.

### Step 2: Session Debrief (conversational)

Ask the user (adapt based on what you already know from the session):

```
Wrapping up. Quick debrief:

1. What did you accomplish? (or I can summarise from our session)
2. Anything in progress that needs continuing?
3. Any blockers or things to remember for next time?
```

If the conversation already makes the answers obvious (you can see what was done),
propose a summary instead of asking:

```
Here's what I captured from this session:

- Accomplished: {X, Y}
- In progress: {Z}
- Note for next time: {W}

Does that look right? Anything to add or change?
```

### Step 3: Update Task Status

Based on the debrief:

1. If tasks were completed → `queue advance` them to done
2. If tasks were started → ensure they're `status: in-progress`
3. If new tasks emerged → offer to `/queue add` them now (brief — don't start a long interview)

For each status change:
```bash
# Update frontmatter in the task file
```

Use Edit tool to modify the `status:` line in affected task files.

### Step 4: Update Goals

Read `{self_dir}/goals.md`. Based on session outcomes:

1. If progress was made on an active thread → add a bullet noting it with today's date
2. If a thread was completed → move it to Recently Completed with date
3. If a new thread emerged → add to Active Threads

Use Edit tool to update the relevant section.

### Step 5: Write Session Note

Create `{ops_dir}/sessions/{YYYY-MM-DD}-{HH}:{MM}.md`:

```markdown
---
date: {YYYY-MM-DDTHH:MM}
duration: {approximate session length if known}
---

# Session — {YYYY-MM-DD}

## Accomplished

- {what got done}
- {what got done}

## In Progress

- {what's mid-stream — with enough context to resume}

## Decisions Made

- {any choices that future-you needs to know about}

## Handoff

{2-3 sentences for next-session-you. What state is the work in?
What's the next concrete step? Any gotchas to remember?}
```

### Step 6: Check for Observations

If observer is enabled, check for pending observations:

```bash
OBS_FILE="/tmp/okm-observations-$(date +%Y-%m-%d).jsonl"
[ -f "$OBS_FILE" ] && echo "HAS_OBSERVATIONS" || echo "NO_OBSERVATIONS"
```

If observations exist, note them in the session file's metadata but don't
process them now — `/reflect` handles that separately.

### Step 7: Auto-commit (if configured)

Read `auto_commit` from config:

- **`commit-only`**:
  ```bash
  cd "{vault_path}"
  git add self/ ops/
  git add knowledge/personal/
  git commit -m "session: {date} — {one-line summary}" 2>/dev/null || true
  ```

- **`commit-and-push`**:
  ```bash
  cd "{vault_path}"
  git add self/ ops/
  git add knowledge/personal/
  git commit -m "session: {date} — {one-line summary}" 2>/dev/null || true
  git push 2>/dev/null || echo "Push failed — will retry next session"
  ```

- **`manual`**: Do nothing. Mention: "Remember to commit when you're ready."

Note: Only commit `self/`, `ops/`, and `knowledge/personal/`. Never commit
inside symlinked paths from this repo.

### Step 8: Closing

Brief output:

```markdown
---

Session wrapped.

✓ {N} task(s) updated
✓ Goals refreshed
✓ Handoff saved to ops/sessions/{filename}
{if auto-commit: "✓ Committed"}
{if observations pending: "○ {N} observations queued for /reflect"}

See you next time. Run /orient to pick up where you left off.
```

---

## Design Principles

1. **Fast and non-intrusive** — the whole wrap should take <2 minutes. Don't make it feel like homework.
2. **Propose, don't interrogate** — if you can infer from the session, summarise and confirm rather than asking from scratch.
3. **Handoff is the most important output** — the session note exists primarily so `/orient` can load it next time. Make the handoff section concise and actionable.
4. **Never block on git** — if commit or push fails, warn but don't make it the user's problem right now. They're trying to STOP working.
5. **Clean closure prevents rumination** — externalising "what's next" into a file frees working memory. This is the cognitive science behind the procedure.

---

## Methodology Updates

If during the session something worked particularly well or poorly (a workflow
pattern, a tool choice, a decomposition approach), ask:

"Anything about how we worked today worth noting in methodology?"

If yes, append to `{self_dir}/methodology.md` under `## Operational Learnings`:

```markdown
- {YYYY-MM-DD}: {one-line learning}
```

Don't force this — only ask if there's a clear signal. Most sessions won't
produce methodology updates.

---

## Edge Cases

- **User wants to wrap but hasn't done anything**: That's OK. Write a minimal session note ("Explored/planned but no concrete output") and don't make them feel guilty.
- **Very long session with many changes**: Summarise at high level. The session note doesn't need to be exhaustive — it's a handoff, not a changelog.
- **User is in a rush**: Accept "just save state" as a valid answer. Write what you know, skip the debrief questions. A terse handoff is better than none.
- **Git conflicts during commit**: Don't resolve them. Warn the user and continue. They can deal with git separately.
- **Multiple sessions in one day**: Timestamp in filename prevents conflicts. Each session gets its own note.
