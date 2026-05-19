---
name: maintain
description: >
  Audit, deduplicate, refactor, link-heal, and split notes within a scoped
  region of the vault. Presents grouped findings for batch approval before
  making changes.
when_to_use: >
  "maintain vault", "audit notes", "find broken links", "deduplicate notes",
  "clean up vault", "fix orphan notes", "check vault health", "sync indexes"
argument-hint: "[path|topic|--all] [--since Nd]"
allowed-tools: Bash Read Write Edit Grep Glob
---

# maintain -- Vault Audit & Curation

Scan a scoped region of the vault for quality issues: duplicates, broken links,
orphans, multi-idea notes, stale claims, and index drift. Collect all findings
silently, present them grouped by type, and execute only approved fixes.

## When to Use

- Periodic vault hygiene (weekly or monthly sweeps)
- After bulk imports or large writing sessions
- When link rot accumulates after note renames
- Before publishing or sharing a section of the vault

## When NOT to Use

- Creating new notes or capturing ideas (use `/connect` or `/zettelkasten`)
- Searching for specific content (use `/retrieve`)
- Reflecting on patterns across notes (use `/reflect`)

## Usage

- `/maintain indexes/python` -- audit notes linked from the python index
- `/maintain "1. Think/" --since 30d` -- audit thinking notes modified in last 30 days
- `/maintain --all` -- full vault audit (warns if >100 notes in scope)

## Configuration

Read configuration at the start of every invocation:

1. Read `.claude/obsidian-knowledge-management.local.md` YAML frontmatter to get `vault_path` and `vault_preset`.
2. Read `{vault_path}/.vault-config.md` YAML frontmatter to get `index_dir` and any preset-specific settings.

Shorthand used below: `VAULT` = resolved `vault_path`, `PRESET` = resolved `vault_preset`.

---

## Protocol

### Phase 0: Resolve Scope

1. Read config (vault_path, vault_preset, index_dir).
2. Determine target scope from the argument:
   - **Path argument** (e.g. `1. Think/`): glob all `.md` files under `VAULT/<path>`.
   - **Topic argument** (e.g. `python`): find the matching index file in `VAULT/<index_dir>/`, read it, collect all `[[linked notes]]` it references.
   - **`--all`**: glob all `.md` files under `VAULT/`.
3. Apply `--since Nd` filter if provided: keep only files with mtime within N days.
4. If scope exceeds 100 notes, warn and ask for confirmation before proceeding.
5. Load all notes in scope into working memory: path, frontmatter, content, outgoing links, word count.

**COMPLETION MARKER:**
```
--- SCOPE RESOLVED: {N} notes in audit region ---
```

### Phase 1: Run Audit Operations

Execute all seven operations against the scoped notes. Do NOT present findings yet -- collect silently.

#### 1. Deduplication

Compare note content pairwise within scope. Flag pairs with >80% content overlap (measured by shared sentences or paragraphs after normalizing whitespace).

For each duplicate pair, record:
- Both file paths
- Overlap percentage
- Which note is longer/more complete
- Suggested action: merge into the more complete note

#### 2. Atomicity Splitting

Detect multi-idea notes using these signals:
- Multiple H2 headings covering different topics
- Word count >300 with unrelated link clusters (links in first half share no targets with links in second half)
- Frontmatter tags spanning multiple unrelated domains

For each candidate, record:
- File path
- Proposed split points (by heading or paragraph boundary)
- Suggested new note titles

#### 3. Link Healing

Find broken `[[wiki-links]]` where the target file does not exist in the vault.

For each broken link, record:
- Source file path and line number
- The broken link text
- Closest fuzzy matches among existing note titles (if any)
- Suggested fix: create stub, fix typo (with suggested correction), or remove link

#### 4. Link Discovery

Identify notes that share topics (via tags, similar titles, or overlapping keywords) but do not link to each other.

For each suggested connection, record:
- Both file paths
- Shared topic/keyword evidence
- Suggested link direction (or bidirectional)

#### 5. Orphan Detection

Find notes with zero incoming links AND zero outgoing links (true orphans), or notes with only outgoing but zero incoming (unreachable notes).

For each orphan, record:
- File path
- Orphan type (isolated or unreachable)
- Suggested fix: connect to a related note, add to an index, or archive

#### 6. Index Sync

For each index file in `VAULT/<index_dir>/`:
- Collect all notes in scope whose tags or path match the index topic.
- Check if the index references each matching note.
- Flag missing entries.

For each missing entry, record:
- Index file path
- Note that should be listed
- Suggested line to add

#### 7. Stale Detection

Find notes with `confidence: amber` (or `confidence: low`) in frontmatter where the file mtime is older than 90 days.

For each stale note, record:
- File path
- Confidence level
- Days since last modification
- Suggested action: re-verify claim, upgrade/downgrade confidence, or mark as historical

**COMPLETION MARKER:**
```
--- AUDIT COMPLETE: {D} duplicates, {A} atomicity issues, {L} broken links, {C} connections suggested, {O} orphans, {I} index gaps, {S} stale notes ---
```

### Phase 2: Preset-Specific Extensions

Apply additional checks based on `PRESET`:

#### Zettelkasten Preset

- **Title format**: Titles in `1. Think/` must be claim-style (a complete assertion, not a topic label). Flag titles that are just nouns or noun phrases.
- **Atomicity enforcement**: Stricter threshold -- any note in `1. Think/` with >1 H2 heading is flagged.
- **Tier placement**: Check that notes match their directory tier (`1. Think/` = atomic claims, `2. Reference/` = literature notes, `3. Work/` = synthesis).
- **Reasoning check**: Notes in `1. Think/` should have a "Why" or "Reasoning" section with 2-5 bullet points. Flag those missing it.
- **AI-voice detection**: Scan for forbidden phrases indicating unedited AI output: "It's important to note", "In conclusion", "Let's delve", "This is significant because", "It should be noted". Flag for rewriting in the author's own voice.

#### PARA Preset

- **Project completion**: Projects inactive for 60+ days (no file modifications in the project folder). Flag for archival to `4. Archive/`.
- **Area freshness**: Area folders with no modifications in 180+ days. Flag for review.

#### Flat Preset

No additional checks beyond the core seven operations.

**COMPLETION MARKER (if preset adds findings):**
```
--- PRESET CHECKS: {N} additional findings for {PRESET} preset ---
```

### Phase 3: Present Findings

Group all findings by operation type. For each group, present:

```
## {Operation Name} ({count} issues)

| # | File | Issue | Suggested Fix |
|---|------|-------|---------------|
| 1 | path/to/note.md | description | fix summary |
| ... | ... | ... | ... |

Action: [fix all] / [review individually] / [skip this category]
```

For splits and merges, show a before/after preview:

```
### Split Preview: "Original Note Title"

**Before:** Single file with 3 H2 sections (450 words)

**After:**
- "Claim A as title.md" (section 1 content, ~150 words)
- "Claim B as title.md" (section 2 content, ~180 words)
- "Claim C as title.md" (section 3 content, ~120 words)

Links from original note will be distributed to the relevant split notes.
Original file will be replaced with a redirect or removed.
```

Wait for operator decision on each category before proceeding.

### Phase 4: Execute Approved Fixes

For each approved category or individually approved fix:

1. **Deduplication**: Merge content into the chosen target note. Update all incoming links from other notes to point to the surviving note. Remove or archive the duplicate.
2. **Atomicity splitting**: Create new note files with appropriate frontmatter. Distribute links. Update or remove the original. Add new notes to relevant indexes.
3. **Link healing**: Apply the chosen fix (create stub with minimal frontmatter, correct the typo in the link text, or remove the broken link).
4. **Link discovery**: Insert `[[link]]` references at the end of the "Related" or "Links" section. If no such section exists, create one.
5. **Orphan detection**: Add to relevant index, insert a link from a related note, or move to an archive directory.
6. **Index sync**: Append missing entries to the index file in alphabetical order.
7. **Stale detection**: Update frontmatter `confidence` field or add a `needs-review: true` flag as directed.

**Self-check before writing**: When generating revised note content (rewrites, merge results, split outputs), scan your own output for the same forbidden AI phrases checked in Phase 2 (zettelkasten preset). Rewrite any such phrases in direct voice before writing to disk.

After each fix, log: `FIXED: {file} -- {action taken}`

### Phase 5: Summary Report

Present a final summary table:

```
## Maintenance Summary

| Category | Found | Fixed | Skipped |
|----------|-------|-------|---------|
| Duplicates | {n} | {n} | {n} |
| Atomicity | {n} | {n} | {n} |
| Broken Links | {n} | {n} | {n} |
| Link Discovery | {n} | {n} | {n} |
| Orphans | {n} | {n} | {n} |
| Index Sync | {n} | {n} | {n} |
| Stale Notes | {n} | {n} | {n} |
| Preset Checks | {n} | {n} | {n} |
| **Total** | **{n}** | **{n}** | **{n}** |

Vault health: {percentage}% of scoped notes are issue-free.
```

---

## Rules

- NEVER auto-fix without presenting findings to the operator first.
- NEVER delete a note without explicit approval. Prefer archiving (move to an archive directory) over deletion.
- NEVER modify notes outside the resolved scope.
- Group similar issues together to reduce decision fatigue.
- Allow batch decisions ("fix all in this category") alongside individual review.
- Show before/after previews for destructive operations (splits, merges).
- Preserve all frontmatter fields when splitting or merging notes.
- When merging, combine tags and links from both notes (deduplicated).
- When splitting, each new note gets its own appropriate frontmatter (title, tags, confidence, date).
- If a split or merge would break links from notes OUTSIDE the current scope, warn the operator and offer to fix those too.
- Respect `.vault-config.md` settings for index_dir and any excluded paths.
- Log all changes made so the operator can review or revert if needed.
