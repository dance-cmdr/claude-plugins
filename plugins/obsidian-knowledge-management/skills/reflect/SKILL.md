---
name: reflect
description: >
  Process the observer's queued observations into proper vault notes, or perform
  freeform reflection to capture session learnings. Use after a work session to
  distill discoveries, decisions, and patterns into atomic knowledge notes.
argument-hint: "[freeform topic]"
allowed-tools: Bash Read Write Edit
---

# reflect -- Observation Processing and Freeform Reflection

Turn session observations and learnings into permanent atomic vault notes.
Operates in two modes depending on whether the observer queue exists.

## When to Use

- End of a work session to capture what was learned
- When the observer has accumulated observations (the queue file exists)
- When you want to manually record a discovery, decision, or insight
- To process `status: pending-reflection` notes left by the Stop hook

## When NOT to Use

- To search or retrieve existing notes (use `/retrieve`)
- To restructure or reorganize the vault (use `/maintain`)
- For initial vault setup (use `/setup`)

---

## Configuration

Read config from `.claude/obsidian-knowledge-management.local.md` YAML frontmatter:

```bash
CONFIG_FILE=".claude/obsidian-knowledge-management.local.md"
```

Extract `vault_path` and `vault_preset` from the frontmatter. Then read vault
structure from `{vault_path}/.vault-config.md` to get `inbox_dir` and `index_dir`.

If the config file does not exist, ask the user to run `/setup` first.

---

## Mode Selection

Check for the observation queue file:

```bash
QUEUE_FILE="/tmp/okm-observations-$(date +%Y-%m-%d).jsonl"
```

- If `$QUEUE_FILE` exists and is non-empty: enter **Observation Processing** mode
- If an argument was provided or no queue exists: enter **Freeform Reflection** mode

Always also check for `status: pending-reflection` notes in the inbox directory
(from prior sessions' Stop hook). Process these alongside whichever mode is active.

---

## Mode 1: Observation Processing

### Step 1 -- Read the queue

```bash
cat "$QUEUE_FILE"
```

Each line is a JSON object:

```jsonl
{"ts":"2026-05-16T14:30:00Z","type":"error_resolved","summary":"Fixed import error by adding missing __init__.py","context":"tools/utils/ was missing package marker"}
```

Valid types: `error_resolved`, `api_discovered`, `decision`, `config_changed`, `repeated_lookup`

### Step 2 -- Group and present

Group observations by type. Present them to the user in a summary table:

```
QUEUED OBSERVATIONS (today)

  error_resolved (2):
    1. Fixed import error by adding missing __init__.py
    2. Resolved circular import by lazy-loading module

  decision (1):
    3. Chose pydantic over dataclasses for config validation

  api_discovered (1):
    4. subprocess.run accepts encoding param directly
```

### Step 3 -- Triage with user

For each observation (or group), ask:

```
For each item, choose:
  [k] Keep -- create a vault note
  [d] Discard -- not worth remembering
  [m] Merge -- combine with another observation into one note
```

Wait for the user's decisions before proceeding.

### Step 4 -- Create notes

For each kept observation, generate an atomic note following the vault note format
(see Note Format below). For merged observations, combine their context into a
single note with a broader claim.

### Step 5 -- Update indexes and clear queue

After all notes are written:

1. Append each new note to the relevant `indexes/_index_{topic}.md`
2. Clear the processed queue file:

```bash
rm "$QUEUE_FILE"
```

---

## Mode 2: Freeform Reflection

### Step 1 -- Elicit learnings

If an argument was provided, use it as the starting topic. Otherwise ask:

```
What did you learn or discover in this session?
(Describe findings, decisions, patterns, or surprises)
```

### Step 2 -- Extract atomic claims

Break the user's response into discrete atomic claims. Each claim should be:

- One idea only (not compound)
- Stated as a fact or decision (not a question)
- Specific enough to be useful later

Present the extracted claims for confirmation:

```
I extracted these atomic claims:

  1. Python's importlib.reload() does not re-execute __init__.py of parent packages
  2. The stripe webhook retry interval doubles after each failure up to 24h
  3. We decided to use UTC everywhere and convert only at display time

Create notes for all, or specify which to keep/discard?
```

### Step 3 -- Create notes

For each confirmed claim, generate a vault note (see Note Format below).

### Step 4 -- Update indexes

Append each new note to the relevant `indexes/_index_{topic}.md`.

---

## Pending-Reflection Notes

Check the inbox directory for markdown files containing `status: pending-reflection`
in their frontmatter:

```bash
grep -rl "status: pending-reflection" "{vault_path}/{inbox_dir}/" 2>/dev/null
```

For each found note:

1. Read its content
2. Present to the user: "This was captured from a previous session: [summary]. Keep and refine, or discard?"
3. If kept: rewrite into proper atomic note format, move to the appropriate topic directory, update frontmatter to remove `status: pending-reflection`
4. If discarded: delete the file

---

## Note Format

Every note created by this skill follows this structure:

```markdown
---
created: YYYY-MM-DD
source: session-reflection
confidence: green
topic: inferred-topic
---

[Atomic claim or fact]

## Context
[What was happening when discovered]

## Links
- [[related-note-1]]

#tag1 #tag2
```

### Field rules

- `created`: today's date
- `source`: always `session-reflection`
- `confidence`: `green` (verified firsthand), `yellow` (likely but not tested), `red` (uncertain/hearsay)
- `topic`: inferred from the content (e.g., `python`, `git`, `architecture`, `stripe`)

### File naming

```
{topic} - {short claim}.md
```

Examples:
- `python - importlib reload does not re-execute parent init.md`
- `stripe - webhook retry interval doubles up to 24h.md`
- `architecture - chose UTC everywhere convert at display.md`

Keep filenames lowercase, concise, and descriptive. No special characters beyond hyphens and spaces.

---

## Index Updates

After creating each note, append to `{vault_path}/{index_dir}/_index_{topic}.md`:

```markdown
- [[{note title}]] — {one-line summary}
```

If the index file does not exist, create it with a header:

```markdown
# {Topic} Index

- [[{note title}]] — {one-line summary}
```

---

## Principles

- **Collaborative**: Always present findings and ask before writing. Never silently create notes.
- **Atomic**: One idea per note. If a claim is compound, split it.
- **Linked**: Every note must link to at least one other note. Search the vault for related notes before writing.
- **No AI voice**: Write in the user's voice. Direct, factual statements. No hedging phrases like "it's worth noting" or "interestingly".
- **Always update indexes**: A note without an index entry is invisible to future retrieval.
- **Confidence-rated**: Be honest about certainty. First-hand experience is green, inference is yellow, hearsay is red.
