---
name: zettelkasten
description: >
  Optional add-on providing Zettelkasten-specific organization, review, and distillation
  for Obsidian vaults using a tiered structure. Triggers on "/zettelkasten organize",
  "/zettelkasten distill", "/zettelkasten review". Requires vault_preset: zettelkasten
  for full functionality; degrades gracefully otherwise.
argument-hint: "[organize|distill|review [path]]"
allowed-tools: Bash Read Edit Write
---

# zettelkasten — Tiered Knowledge Organization

Organize, distill, and review notes using Zettelkasten principles within an Obsidian vault.

## When to Use

- Inbox has accumulated notes that need categorization into tiers
- You learned something and want to capture it as an atomic thinking note
- You want quality review of existing notes against Zettelkasten rules
- Observer created `status: pending-reflection` notes that need processing

## When NOT to Use

- Finding or retrieving notes (use `/retrieve`)
- Fixing broken links or orphan notes (use `/maintain`)
- General vault setup or configuration (use `/setup`)
- Capturing a reflection in the moment (use `/reflect`; this skill processes those later)

## Prerequisites

Read the plugin config to determine vault path and preset:

```bash
cat .claude/obsidian-knowledge-management.local.md
```

Extract `vault_path` and `vault_preset` from YAML frontmatter.

If `vault_preset` is `zettelkasten`, also read the vault's own rules:
- `{vault_path}/1. Think/THINK_NOTES_RULES.md`
- `{vault_path}/2. Reference/REFERENCE_RULES.md`

These files are authoritative. If they conflict with guidance below, the vault files win.

## Mode: Organize

**Command**: `/zettelkasten organize`

**Requires**: `vault_preset: zettelkasten`

If preset is not zettelkasten, inform the user this mode requires the 5-tier structure and stop.

### Procedure

1. **List inbox contents**:
   ```bash
   find "{vault_path}/0. Inbox" -name "*.md" -type f | head -50
   ```

2. **Also find pending-reflection notes** (created by /reflect via the observer):
   ```bash
   grep -rl "status: pending-reflection" "{vault_path}/0. Inbox" 2>/dev/null
   ```

3. **For each note, read and categorize**:
   - **Think** (`1. Think/`) — Contains a single atomic insight in the user's own words
   - **Reference** (`2. Reference/`) — Structured lookup material, searchable, disposable
   - **Work** (`3. Work/`) — Synthesis, drafts, presentations in progress

4. **Split mixed notes**: If a note contains both reference material and an insight, split into two files. The insight goes to Think, the reference to Reference.

5. **Ensure linking**: Every Think note must link to at least one other Think note. Suggest candidates based on content similarity.

6. **Anti-hoarding check**: Flag Reference notes that duplicate easily-searchable information. Ask: "Would you find this faster via a search engine?"

7. **Present plan before acting**: Show the proposed moves as a table. Wait for confirmation.

   ```
   | Note | Current | Proposed | Reason |
   |------|---------|----------|--------|
   | ...  | Inbox   | Think    | ...    |
   ```

8. **Execute moves** only after user confirms.

## Mode: Distill

**Command**: `/zettelkasten distill`

**Works with any vault_preset** (degrades gracefully).

### Procedure

1. **Gather input**: Ask what the user learned. Accept free-form text, a conversation summary, or a file path.

2. **Extract atomic ideas**: Identify distinct claims or insights. Each becomes one note.

3. **Draft claim-style titles**: Titles are assertive statements, not topics or questions.
   - Good: "Retry logic without backoff causes cascade failures"
   - Good: "GraphQL subscriptions require persistent connections"
   - Bad: "Retry logic" (topic, not claim)
   - Bad: "How do retries work?" (question, not claim)

4. **Draft note body** for each idea:
   - One paragraph: the claim in the user's own words
   - **Why** section: 2-5 bullets explaining the reasoning
   - Links section: connections to existing notes

5. **Find linking candidates**: Search existing notes for related content.
   ```bash
   grep -rl "relevant-keyword" "{vault_path}/1. Think/" 2>/dev/null | head -10
   ```

6. **Write destination**:
   - If `vault_preset: zettelkasten` — write to `{vault_path}/1. Think/`
   - Otherwise — write to `{vault_path}/inbox/` or `{vault_path}/notes/` (whichever exists)

7. **Present drafts before writing**: Show each note. Confirm or refine collaboratively.

## Mode: Review

**Command**: `/zettelkasten review [path]`

**Partial functionality without zettelkasten preset**.

### Procedure

1. **Determine scope**: If `[path]` provided, review that file or directory. Otherwise, ask.

2. **Read notes** in scope.

3. **Apply rules based on preset**:

   **If zettelkasten preset — full review against tier rules:**

   For Think notes, check:
   - Atomicity: exactly ONE idea per note
   - Title format: assertive claim, not topic or question
   - Own words: no raw quotes, no copy-paste from sources
   - Stands alone: comprehensible without reading the source
   - Why section: 2-5 reasoning bullets present
   - Linking: at least one link to another Think note
   - Forbidden content: no TODOs, no draft paragraphs, no code snippets, no runbooks, no raw quotes

   For Reference notes, check:
   - Short and structured: scannable, not essay-form
   - Searchable: clear headings, keywords present
   - Anti-hoarding: provides value beyond what a search engine gives
   - Promotion opportunity: if it contains an insight, suggest creating a Think note

   **If NOT zettelkasten preset — general quality checks only:**
   - Note has a clear title
   - Content is focused (not a grab-bag)
   - Links exist where relevant
   - No orphaned drafts or empty stubs

4. **Present findings**: Group by severity (issues, suggestions, praise). Show specific lines.

5. **Refine collaboratively**: Offer to fix issues with user approval. Never edit without confirmation.

## Thinking Notes Rules (Quick Reference)

A valid thinking note:
- Contains exactly ONE idea (atomic)
- Has a claim-style title (assertive statement)
- Written in the user's own words
- Stands alone without needing the source
- Includes a Why section with 2-5 reasoning bullets
- Links to at least one other thinking note

A thinking note must NOT contain:
- TODOs or action items
- Draft paragraphs or essay sections
- Code snippets or runbooks
- Raw quotes from sources
- Multiple unrelated ideas

## Reference Notes Rules (Quick Reference)

- Shortcut layer: helps FIND information, not THINK about it
- Short, direct, structured, scannable
- Anti-hoarding: skip what a search engine finds easily
- Promotion rule: if an insight emerges, create a separate Think note
- Disposable by design: deleting it loses convenience, not knowledge

## Integration with Other Skills

| Skill | Relationship |
|-------|-------------|
| `/reflect` | Creates notes in inbox with `status: pending-reflection` |
| `/zettelkasten organize` | Processes those notes into tiers |
| `/maintain` | Fixes structural issues (broken links, orphans) |
| `/retrieve` | Finds notes; this skill improves their quality |

## Guidance

- Confirm before editing any file
- No AI voice: avoid "It is worth noting", "This represents", "In conclusion"
- Succinct prose: say it once, clearly
- Progressive disclosure: start with the summary, details on request
- Collaborative: present options, let the user decide
