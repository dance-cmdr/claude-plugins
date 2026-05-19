---
name: connect
description: >
  Load relevant vault knowledge into the current session at startup. Reads vault
  config, infers relevant topics from working directory and git context, loads
  matching topic indexes, scans recent notes, and presents a compact context
  summary. The "RAG at session start" mechanism.
when_to_use: >
  "connect vault", "load vault context", "what do I know about",
  "prime context", "session context", "load my notes"
allowed-tools: Bash Read Grep Glob
---

# connect -- Session Context Loading

Load your Obsidian vault context at the start of a session so relevant knowledge
is immediately available without manual retrieval.

## When to Use

- At session start to prime context with relevant vault knowledge
- When switching project context and needing fresh topic alignment
- After vault changes to reload updated indexes

## When NOT to Use

- For deep search across the full vault (use /retrieve instead)
- For writing or modifying notes (use /reflect or direct edits)
- When vault is not yet configured (use /setup first)

---

## Procedure

### Step 1: Read Plugin Configuration

Read `.claude/obsidian-knowledge-management.local.md` from the project root.
Extract YAML frontmatter fields:

- `vault_path` (required) -- absolute path to the Obsidian vault
- `vault_preset` (optional, default: `zettelkasten`)

If the config file does not exist or `vault_path` is missing, stop and instruct
the user to run `/setup` first.

### Step 2: Read Vault Config

Read `{vault_path}/.vault-config.md` to understand vault structure. Extract:

- `index_dir` -- directory containing topic indexes (default: varies by preset)
- `inbox_dir` -- inbox directory path
- `topics` -- list of known topic labels

If `.vault-config.md` does not exist, fall back to preset defaults:

| Preset | index_dir | inbox_dir |
|--------|-----------|-----------|
| `zettelkasten` | `1. Think` | `0. Inbox` |
| `flat` | `.` | `inbox` |
| `para` | `Areas` | `Inbox` |

### Step 3: Infer Relevant Topics

Gather context signals from the current working environment:

```bash
# Working directory name
basename "$(pwd)"

# Git repo name (if in a git repo)
git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||'

# Recent commit messages (last 5)
git log --oneline -5 2>/dev/null

# File extensions in working directory (top 5 by frequency)
find . -maxdepth 2 -type f | sed 's|.*\.||' | sort | uniq -c | sort -rn | head -5
```

Match these signals against the vault's known `topics` list. Matching rules:

- Directory/repo name contains a topic label (case-insensitive)
- Commit messages mention a topic label
- File extensions map to topics (e.g., `.py` -> `python`, `.rs` -> `rust`, `.tf` -> `terraform`)

If no topics match, select up to 5 indexes alphabetically as a general context load.

### Step 4: Load Topic Indexes

For each matched topic, read the corresponding index file:

```
{vault_path}/{index_dir}/_index_{topic}.md
```

Read the full content of each index. These are compact note catalogs that
provide an overview of what the vault knows about each topic.

If an index file does not exist for a matched topic, skip it silently.

Cap at 5 indexes maximum to avoid context bloat.

### Step 5: Scan Recent Notes

Find notes modified within the last 7 days:

```bash
find "{vault_path}" -name "*.md" -mtime -7 -not -path "*/.trash/*" -not -name ".*"
```

For each recent note (up to 50), read only the YAML frontmatter (between the
opening `---` and closing `---` lines). Extract:

- Title (from `title:` field or filename)
- Modified date

Sort by modification date, most recent first.

If more than 10 recent notes exist, present only the top 10 with a count of
remaining: "(+N more)".

### Step 6: Check Inbox

Count pending items in the inbox directory:

```bash
find "{vault_path}/{inbox_dir}" -name "*.md" -type f | wc -l
```

Count pending-reflection notes specifically (files matching `*-observation.md`
or containing `status: pending-reflection` in frontmatter):

```bash
grep -rl "status: pending-reflection" "{vault_path}/{inbox_dir}" 2>/dev/null | wc -l
```

### Step 7: Present Context Summary

Output the context summary in this exact format:

```markdown
## Vault Context (obsidian-knowledge-management)

**Relevant indexes loaded:** {comma-separated topic list, or "none (general load)"}
**Recent notes (7d):**
- [[{note title}]] ({N}d ago)
- [[{note title}]] ({N}d ago)
...

**Open inbox items:** {count} ({reflection_count} pending reflection)

Use /retrieve [query] for deeper search. Use /reflect to process pending observations.
```

If the vault is empty (no indexes, no recent notes, no inbox items), output:

```markdown
## Vault Context (obsidian-knowledge-management)

**Vault is empty.** No indexes, recent notes, or inbox items found.

Use /setup to configure vault structure, or start adding notes to your vault.
```

---

## Edge Cases

- **Empty vault**: Display the empty-vault message. Do not error.
- **No matching topics**: Load up to 5 indexes alphabetically. Note "none (general load)" in output.
- **Large vault (>50 recent notes)**: Only read frontmatter of the 50 most recent. Display top 10.
- **Missing .vault-config.md**: Use preset defaults from Step 2 fallback table.
- **Vault path does not exist**: Stop with clear error: "Vault path does not exist: {path}. Run /setup to reconfigure."
- **Permission errors**: Report which paths are inaccessible, continue with what is readable.
