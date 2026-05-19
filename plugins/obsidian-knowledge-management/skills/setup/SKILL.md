---
name: setup
description: >
  Set up a new Obsidian vault or adopt an existing one as a knowledge graph.
  Interviews the user for vault path, preset selection, topics, and observer
  preference, then generates vault structure with indexes and rules files.
  Use when first installing the plugin, onboarding a new vault, or resetting
  vault configuration.
argument-hint: "[vault-path]"
allowed-tools: Bash Read Write Edit
---

# setup -- Obsidian Knowledge Management Onboarding

Walk the user from zero to a fully configured knowledge vault in one session.
Covers: vault location, preset selection, topic seeding, observer preference,
directory scaffolding, rules files, index generation, and config persistence.

## When to Use

- First time using the obsidian-knowledge-management plugin
- Adopting an existing Obsidian vault for use with this plugin
- Resetting vault configuration after a major restructure
- The plugin fired a vault-not-found gate (missing config)

## When NOT to Use

- Adding a single note or topic (use `/retrieve` or `/connect`)
- Routine vault maintenance (use `/maintain`)
- Restructuring note content without changing vault layout

## Tool Access

`Bash` -- creating directories, checking existing vault structure. `Read` --
detecting existing vault files and reading current config. `Write` -- generating
config files, rules files, and index stubs. `Edit` -- updating existing config
when re-running setup on an already-configured vault.

---

## Phase 1: Interview

Run through these questions sequentially. If the user provided a vault path as
an argument, skip Step 1. Adapt based on answers -- skip what is already done.

### Step 1 -- Vault Path

Ask: **"Where is your Obsidian vault? (full path, e.g., ~/Documents/my-vault)"**

- Expand `~` to the user's home directory
- If the path exists and contains `.md` files, flag it as an existing vault (Phase 2 will detect structure)
- If the path does not exist, confirm: "This directory doesn't exist yet. Create it as a new vault?"

### Step 2 -- Preset Selection

Ask:

```
Choose a vault structure preset:
  (1) Zettelkasten -- tiered thinking system (Inbox, Think, Reference, Work, Archive, indexes)
  (2) Flat -- minimal structure (notes, references, inbox, indexes)
  (3) PARA -- Projects/Areas/Resources/Archive with inbox and indexes
```

Explain briefly what each offers:
- **Zettelkasten**: Best for building a connected thinking system. Atomic notes with claim-style titles, progressive refinement from inbox to archive.
- **Flat**: Best for simplicity. All notes in one place, references separate, minimal ceremony.
- **PARA**: Best for action-oriented workflows. Organize by project and area of responsibility.

### Step 3 -- Topics

Ask: **"What are your primary knowledge topics? (comma-separated, e.g., python, distributed-systems, machine-learning)"**

These become the seed index files in `indexes/`. Each topic gets an `_index_{topic}.md` file that serves as an entry point for retrieval.

Validate:
- Convert to lowercase kebab-case
- Minimum 1 topic required
- Suggest 3-7 topics as a good starting range

### Step 4 -- Observer Preference

Ask: **"Enable the session observer? It watches for emergent patterns and suggests connections during your work sessions. (yes/no, default: yes)"**

Explain: The observer is a background process that periodically scans session context for knowledge worth capturing. It can be toggled later in config.

---

## Phase 2: Existing Vault Detection

**Skip this phase if the vault path does not exist or contains no `.md` files.**

If the vault already has markdown files, detect the existing structure:

### Detection Logic

```
1. Check for tier directories (numbered prefixes like "1. Think/", "2. Reference/"):
   → If found: detected_preset = "zettelkasten"

2. Check for PARA directories (Projects/, Areas/, Resources/, Archive/):
   → If found: detected_preset = "para"

3. Otherwise:
   → detected_preset = "flat"
```

Run detection:

```bash
VAULT="<vault_path>"

# Check for zettelkasten tier structure
if ls -d "$VAULT"/[0-9]*. */ 2>/dev/null | grep -q .; then
  echo "DETECTED: zettelkasten"
# Check for PARA structure
elif [ -d "$VAULT/Projects" ] && [ -d "$VAULT/Areas" ] && [ -d "$VAULT/Resources" ]; then
  echo "DETECTED: para"
else
  echo "DETECTED: flat"
fi
```

### Present Detection Results

Tell the user:

```
I detected an existing {detected_preset} structure in your vault:
  {list of found directories}

Would you like to:
  (1) Keep detected structure and add infrastructure (indexes, config, rules) non-destructively
  (2) Override with your selected preset ({user_preset}) -- this only ADDS directories, never deletes
```

If the user's chosen preset matches the detected structure, proceed directly.
If they differ, confirm the override and note that no existing files will be removed.

### Non-Destructive Addition

When adopting an existing vault:
- NEVER delete or move existing files
- NEVER overwrite existing `.md` files without asking
- Only ADD new infrastructure: `indexes/`, `.vault-config.md`, `VAULT_RULES.md`
- If `indexes/` already exists, check for existing index files before creating new ones
- If rules files already exist, ask before overwriting

---

## Phase 3: Vault Scaffolding

### Directory Structure by Preset

**Zettelkasten:**

```bash
VAULT="<vault_path>"
mkdir -p "$VAULT/0. Inbox"
mkdir -p "$VAULT/1. Think"
mkdir -p "$VAULT/2. Reference"
mkdir -p "$VAULT/3. Work"
mkdir -p "$VAULT/4. Archive"
mkdir -p "$VAULT/indexes"
```

**Flat:**

```bash
VAULT="<vault_path>"
mkdir -p "$VAULT/notes"
mkdir -p "$VAULT/references"
mkdir -p "$VAULT/inbox"
mkdir -p "$VAULT/indexes"
```

**PARA:**

```bash
VAULT="<vault_path>"
mkdir -p "$VAULT/Projects"
mkdir -p "$VAULT/Areas"
mkdir -p "$VAULT/Resources"
mkdir -p "$VAULT/Archive"
mkdir -p "$VAULT/inbox"
mkdir -p "$VAULT/indexes"
```

### Generate Index Files

For each topic from the interview, create `indexes/_index_{topic}.md`:

```markdown
---
topic: {topic}
created: {YYYY-MM-DD}
type: index
---

# {Topic Title Case}

Entry point for knowledge related to **{topic}**.

## Key Notes

<!-- Links to important notes on this topic will be added here -->
<!-- Format: [[note-title]] -- one-line summary -->

## Open Questions

<!-- Questions worth exploring on this topic -->

## Connections

<!-- Cross-references to related topic indexes -->
```

### Generate `.vault-config.md`

Write `{vault_path}/.vault-config.md`:

```markdown
---
preset: {preset}
created: {YYYY-MM-DD}
topics:
  - {topic1}
  - {topic2}
  - ...
index_dir: indexes
inbox_dir: {inbox_dir_for_preset}
observer_enabled: {true|false}
---

# Vault Configuration

This file is read by the obsidian-knowledge-management plugin to understand
your vault structure. Edit the frontmatter to update settings.

## Preset: {preset}

{Brief description of the chosen preset and its directory layout}

## Topics

{Numbered list of configured topics with links to their index files}

## Paths

| Purpose | Path |
|---------|------|
| Inbox | {inbox_dir} |
| Indexes | indexes/ |
{Additional rows based on preset}
```

The `inbox_dir` values by preset:
- Zettelkasten: `0. Inbox`
- Flat: `inbox`
- PARA: `inbox`

### Generate `VAULT_RULES.md`

Write `{vault_path}/VAULT_RULES.md`:

```markdown
# Vault Rules

These rules govern how notes are created and linked in this vault.

## Note Format

Every note MUST have YAML frontmatter with at minimum:

```yaml
---
title: Descriptive title of the note
created: YYYY-MM-DD
tags: [relevant, tags]
---
```

## Linking

- Use `[[wikilinks]]` for internal links between notes
- Every note should link to at least one other note or index
- Prefer linking to specific claims over broad topics
- When referencing external sources, include the URL in the frontmatter

## Naming

- File names should be descriptive enough to understand without opening
- Format: `{topic} - {short claim}.md` (e.g., `python - asyncio tasks must be awaited.md`)
- Spaces are acceptable (Obsidian handles them natively)
- Avoid special characters beyond hyphens and spaces

## Inbox Processing

New captures go to the inbox directory. During maintenance:
1. Review inbox items
2. Refine into proper notes with frontmatter and links
3. Move to the appropriate directory based on vault preset
4. Update relevant index files
```

---

## Phase 4: Preset-Specific Rules Files

### Zettelkasten Preset Only

**Create `{vault_path}/1. Think/THINK_NOTES_RULES.md`:**

```markdown
# Think Notes Rules

These rules apply to all notes in the `1. Think/` directory.

## Core Principles

1. **One idea per note** -- Each note contains exactly one atomic claim or concept.
   If you find yourself writing "also" or "another thing", split into a separate note.

2. **Claim-style titles** -- Titles are assertions, not topics.
   - Good: "Distributed consensus requires at least 2f+1 nodes"
   - Bad: "Distributed consensus" or "Notes on Raft"

3. **Own words only** -- Never copy-paste. Restate ideas in your own language.
   This forces understanding and reveals gaps in comprehension.

4. **Links are mandatory** -- Every think note MUST link to at least one other
   think note or reference note. Orphan notes are inbox items that haven't been
   properly integrated.

5. **Progressive refinement** -- Notes start rough and improve over time.
   Don't aim for perfection on first write. Revisit and sharpen.

## Format

```yaml
---
title: Claim-style title stating the core idea
created: YYYY-MM-DD
tags: [topic1, topic2]
source: [[reference-note]] or URL (if derived from a source)
---
```

Body: 3-10 sentences elaborating the claim. End with links to related notes.

## Anti-Patterns

- Topic notes ("Everything about X") -- split into atomic claims
- Copy-paste from sources -- restate in own words
- Orphan notes with no links -- connect or move back to inbox
- Multi-paragraph essays -- distill to the core claim
```

**Create `{vault_path}/2. Reference/REFERENCE_RULES.md`:**

```markdown
# Reference Rules

These rules apply to all notes in the `2. Reference/` directory.

## Purpose

Reference notes capture information FROM external sources: books, papers,
articles, documentation, talks, conversations. They exist to support think
notes with evidence and attribution.

## Format

```yaml
---
title: "Source Title - Author (Year)"
created: YYYY-MM-DD
type: reference
source_url: https://...
source_type: [book|paper|article|docs|talk|conversation]
tags: [topic1, topic2]
---
```

Body: Key points, quotes (attributed), and your initial reactions.
End with `## Atomic Claims` section listing think notes derived from this source.

## Anti-Hoarding Rule

**Do not create reference notes for things you might read later.**

A reference note is created ONLY when:
1. You have actually read/watched/listened to the source
2. You can write at least one key takeaway in your own words
3. The source connects to an existing topic in your vault

Bookmarks and "to read" items go in the inbox, not references.

## Linking

- Link TO the source (URL in frontmatter)
- Link FROM think notes that cite this reference
- Cross-reference related references via tags
```

### PARA and Flat Presets

These presets do not get rules files by default. The `VAULT_RULES.md` at the
root is sufficient. If the user asks for additional structure, offer to create
topic-specific rules in relevant directories.

---

## Phase 5: Plugin Configuration

### Write `.claude/obsidian-knowledge-management.local.md`

This file persists the user's configuration for the plugin. Write it at the
PROJECT level (where `.claude/` lives), not inside the vault.

Determine the correct location:
- If running inside a project with `.claude/` directory, write there
- Otherwise, write to `~/.claude/obsidian-knowledge-management.local.md`

```markdown
---
vault_path: {absolute_vault_path}
vault_preset: {preset}
observer_enabled: {true|false}
---

# Obsidian Knowledge Management - Local Configuration

Plugin configuration for this machine. Edit the YAML frontmatter to change settings.

## Vault

- **Path**: {vault_path}
- **Preset**: {preset}
- **Topics**: {comma-separated topic list}

## Observer

The session observer is {enabled|disabled}. Toggle by changing `observer_enabled`
in the frontmatter above.
```

---

## Phase 6: Verification

After scaffolding is complete, verify the setup:

### Check 1 -- Directory Structure

```bash
VAULT="<vault_path>"
echo "=== Directory Structure ==="
find "$VAULT" -type d -maxdepth 2 | sort
```

Confirm all expected directories exist for the chosen preset.

### Check 2 -- Index Files

```bash
echo "=== Index Files ==="
ls "$VAULT/indexes/"
```

Confirm one `_index_{topic}.md` file exists for each configured topic.

### Check 3 -- Config Files

```bash
echo "=== Config Files ==="
[ -f "$VAULT/.vault-config.md" ] && echo "OK: .vault-config.md" || echo "FAIL: .vault-config.md missing"
[ -f "$VAULT/VAULT_RULES.md" ] && echo "OK: VAULT_RULES.md" || echo "FAIL: VAULT_RULES.md missing"
```

### Check 4 -- Plugin Config

Verify the local config file exists and contains correct frontmatter:

```bash
CONFIG_PATH=".claude/obsidian-knowledge-management.local.md"
[ -f "$CONFIG_PATH" ] && echo "OK: plugin config" || echo "FAIL: plugin config missing"
```

### Check 5 -- Zettelkasten Rules (if applicable)

```bash
if [ "{preset}" = "zettelkasten" ]; then
  [ -f "$VAULT/1. Think/THINK_NOTES_RULES.md" ] && echo "OK: think rules" || echo "FAIL: think rules missing"
  [ -f "$VAULT/2. Reference/REFERENCE_RULES.md" ] && echo "OK: reference rules" || echo "FAIL: reference rules missing"
fi
```

---

## Phase 7: Briefing

After setup completes, brief the user:

### Your vault is ready

```
SETUP COMPLETE

[x] Vault: {vault_path}
[x] Preset: {preset}
[x] Topics: {topic_list}
[x] Indexes: {count} topic indexes created
[x] Observer: {enabled|disabled}
[x] Config: .claude/obsidian-knowledge-management.local.md written
{if zettelkasten:}
[x] Rules: THINK_NOTES_RULES.md + REFERENCE_RULES.md created
{end if}
```

### Quick start

- **Capture something**: Drop a note in `{inbox_dir}/` or tell me what to capture
- **Retrieve knowledge**: Use `/retrieve` to search your vault by topic
- **Reflect on a session**: Use `/reflect` after a work session to distill learnings
- **Connect ideas**: Use `/connect` to find and create links between notes
- **Maintain the vault**: Use `/maintain` to review inbox, check orphans, update indexes

### How the plugin works

The obsidian-knowledge-management plugin treats your vault as a knowledge graph.
Notes are nodes, wikilinks are edges. The skills help you:

1. **Capture** -- Get ideas into the vault quickly (inbox)
2. **Refine** -- Shape raw captures into proper notes with links
3. **Retrieve** -- Find relevant knowledge when you need it
4. **Reflect** -- Extract learnings from work sessions
5. **Connect** -- Discover and create relationships between ideas
6. **Maintain** -- Keep the vault healthy (orphans, stale indexes, inbox review)

### Changing configuration

Edit `.claude/obsidian-knowledge-management.local.md` frontmatter to change:
- `vault_path` -- point to a different vault
- `vault_preset` -- change structure (requires re-running setup)
- `observer_enabled` -- toggle the session observer

Or re-run `/setup` to start the interview again.

---

## Error Handling

- **Permission denied on vault path**: Suggest checking directory permissions or choosing a different location
- **Vault path is inside a git repo**: Warn that large vaults may slow git operations; suggest adding to `.gitignore` if the vault is not meant to be version-controlled
- **Existing vault with conflicts**: Never overwrite existing files. Always ask before modifying anything that already exists
- **Config directory missing**: Create `.claude/` if it doesn't exist (it's standard for Claude Code projects)
