---
name: connect
description: >
  Load relevant knowledge from all linked vaults into the current session.
  Reads vault config, infers relevant topics from working directory and git
  context, searches across all domain vaults and personal knowledge, and
  presents a compact context summary. The "RAG at session start" mechanism.
when_to_use: >
  "connect vault", "load vault context", "what do I know about",
  "prime context", "session context", "load my notes"
allowed-tools: Bash Read Grep Glob
---

# connect -- Session Context Loading

Load relevant knowledge from your second-brain and all linked domain vaults
so context is immediately available without manual retrieval.

## When to Use

- At session start to prime context with relevant vault knowledge
- When switching project context and needing fresh topic alignment
- After vault changes to reload updated indexes

## When NOT to Use

- For deep search across the full vault (use /retrieve instead)
- For writing or modifying notes (use /reflect or direct edits)
- When vault is not yet configured (use /setup first)
- For session orientation with tasks/goals (use /orient instead)

---

## Procedure

### Step 1: Read Plugin Configuration

Read `.claude/obsidian-knowledge-management.local.md` from the project root.
Extract YAML frontmatter fields:

- `vault_path` (required) -- absolute path to the second-brain
- `vault_preset` (optional, default: `orchestrated`)

If the config file does not exist or `vault_path` is missing, stop and instruct
the user to run `/setup` first.

### Step 2: Read Vault Config

Read `{vault_path}/.vault-config.md` to understand structure. Extract:

- `knowledge_vaults` -- list of linked domain vaults (name, symlink path, domain description)
- `personal_knowledge_dir` -- path to personal knowledge (default: `knowledge/personal`)
- `inbox_dir` -- inbox directory path

For orchestrated preset, the search spans:
- `{vault_path}/{personal_knowledge_dir}/` (personal cross-domain notes)
- Each `{vault_path}/{symlink}` from `knowledge_vaults` list

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

**Domain matching** (new for orchestrated preset):
Match signals against each vault's `domain` description. For example, if working
in a PythonAnywhere repo and a vault has `domain: "PythonAnywhere infrastructure"`,
prioritise that vault's indexes.

**Topic matching** (within each vault):
- If the vault has an `indexes/` directory, search index filenames for topic matches
- If the vault uses zettelkasten (detected by `1. Think/` directory), search `1. Think/` titles
- Directory/repo name contains a topic label (case-insensitive)
- Commit messages mention a topic label
- File extensions map to topics (e.g., `.py` -> `python`, `.tf` -> `terraform`)

If no topics match, select up to 5 indexes alphabetically as a general context load.

### Step 4: Load Topic Indexes

For each matched vault and topic, search for index files:

```bash
# Check for indexes/ directory in each vault
for VAULT_LINK in {vault_path}/knowledge/*/; do
  find "$VAULT_LINK" -path "*/indexes/*" -name "*{topic}*" 2>/dev/null
done

# Also check personal knowledge
find "{vault_path}/{personal_knowledge_dir}" -name "*index*" -name "*{topic}*" 2>/dev/null
```

Read the full content of each matching index. Cap at 5 indexes total across all vaults.

### Step 5: Scan Recent Notes

Find notes modified within the last 7 days across ALL knowledge paths:

```bash
BRAIN="{vault_path}"
find "$BRAIN/knowledge" -name "*.md" -mtime -7 -not -path "*/.trash/*" -not -path "*/.git/*" -not -name ".*"
```

For each recent note (up to 50), read only the YAML frontmatter. Extract:

- Title (from `title:` field or filename)
- Modified date
- Which vault it belongs to (from path)

Sort by modification date, most recent first.
If more than 10, present top 10 with "(+N more)".

### Step 6: Check Inbox

Count pending items in the brain's inbox:

```bash
find "{vault_path}/{inbox_dir}" -name "*.md" -type f | wc -l
```

Count pending-reflection notes:

```bash
grep -rl "status: pending-reflection" "{vault_path}/{inbox_dir}" 2>/dev/null | wc -l
```

### Step 7: Present Context Summary

```markdown
## Knowledge Context

**Vaults loaded:** {list of vault names that matched, or "all (general load)"}
**Relevant indexes:** {comma-separated topic list from matched indexes}

**Recent notes (7d):**
- [[{note title}]] ({vault-name}, {N}d ago)
- [[{note title}]] ({vault-name}, {N}d ago)
...

**Inbox:** {count} items ({reflection_count} pending reflection)

Use /retrieve [query] for deeper search. Use /orient for task/goals briefing.
```

If no knowledge exists yet:

```markdown
## Knowledge Context

**No knowledge loaded.** Vaults are empty or not yet linked.

Use /setup --add-vault to link a domain vault, or start capturing to inbox/.
```

---

## Edge Cases

- **Empty vaults**: Display count of linked vaults but note they're empty. Do not error.
- **No matching topics**: Load up to 5 indexes alphabetically across all vaults.
- **Broken symlinks**: Warn which vault link is broken, continue with others.
- **Large vault (>50 recent notes)**: Only read frontmatter of the 50 most recent. Display top 10.
- **Missing .vault-config.md**: Stop with clear error pointing to /setup.
- **Single-vault (non-orchestrated) preset**: Fall back to searching just `vault_path` directly (backwards compatible).
- **Permission errors**: Report which paths are inaccessible, continue with what is readable.
