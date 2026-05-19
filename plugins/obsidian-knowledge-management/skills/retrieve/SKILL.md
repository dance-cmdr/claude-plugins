---
name: retrieve
description: >
  On-demand knowledge retrieval from the Obsidian vault using a 5-step strategy:
  index lookup, full-text grep, link traversal, backlink scan, and recency weighting.
  Use when you need to find existing notes, gather context on a topic, or explore
  connected ideas in the vault.
argument-hint: "[query]"
allowed-tools: Bash Read Grep Glob
---

# retrieve -- Vault Knowledge Retrieval

Retrieve relevant notes from the Obsidian vault using a multi-step search strategy
that combines text matching with graph traversal for comprehensive results.

## When to Use

- Looking up prior thinking on a topic before starting new work
- Gathering context from existing notes to inform a decision
- Finding connected ideas across the vault's link graph
- Checking what already exists before creating new notes

## When NOT to Use

- Creating or modifying notes (use `maintain` skill)
- Reorganizing vault structure (use `zettelkasten` skill)
- Reflecting on recent sessions (use `reflect` skill)

## Configuration

Read config from `.claude/obsidian-knowledge-management.local.md` YAML frontmatter to get `vault_path`.
Then read `{vault_path}/.vault-config.md` to get `index_dir`.

## Retrieval Strategy

Execute these 5 steps in order. Stop early if sufficient context is found.

### Step 1: Index Lookup

Grep query keywords in `{vault_path}/{index_dir}/` files. Extract matching wiki-link
entries from index notes. Index notes are high-signal curated entry points.

```bash
grep -ril --include="*.md" "{query}" "{vault_path}/{index_dir}/"
```

For each matching index file, extract `[[wiki-link]]` entries from lines containing
the query term.

### Step 2: Full-Text Grep

Search the entire vault for notes containing query terms:

```bash
grep -ril --include="*.md" "{query}" "{vault_path}/" | grep -v "/\."
```

Exclude hidden directories. Get matching lines plus 2 lines of context for the top
results.

If vault contains >200 notes, limit grep results to 10 before proceeding to traversal.

### Step 3: Link Traversal (1-2 hops)

For the top 5 matches from steps 1-2:

1. Extract all outgoing `[[wiki-links]]` from the note
2. Read linked notes (frontmatter + first 3 lines only for efficiency)
3. For the top 3 most relevant linked notes, follow one more hop

This surfaces ideas connected by the author's intentional linking.

### Step 4: Backlink Scan

For the top 5 matches, find notes that link TO them:

```bash
grep -rl "\[\[{title}\]\]" "{vault_path}/" | grep -v "/\."
```

Backlinks reveal how other notes reference the matched content, exposing
additional context and related thinking.

### Step 5: Recency Weighting

Sort and rank all collected results:

1. Index matches (highest signal -- curated by the user)
2. Recent full-text matches (modified within last 30 days)
3. Older full-text matches
4. Graph-connected notes (reached via links/backlinks)

Use file modification time for recency sorting (`stat -f %m` on macOS, `stat -c %Y` on Linux).

## Token Efficiency Rules

- Read full content only for top 5 direct matches
- For graph-connected notes (hops), read only frontmatter + first 3 lines
- Cap total notes read at 20
- If vault >200 notes, limit grep to 10 results before traversal

## Output Format

Present results in this structure:

```markdown
## Retrieved: "{query}"

### Direct matches (N)
1. **[[Note Title]]** -- excerpt of matching content
   Links to: [[x]], [[y]]
   Linked from: [[z]]

2. **[[Another Note]]** -- excerpt
   Links to: [[a]]
   Linked from: [[b]], [[c]]

### Graph context (via links)
- [[Direct Match]] -> [[1-hop Note]] -> [[2-hop Note]]
- [[Another Match]] -> [[Related Idea]]

### Suggestions
- Related indexes: [[_index_topic]]
- Try also: "alternative search term"
```

## Usage Examples

- `/retrieve "spaced repetition"` -- find notes about spaced repetition
- `/retrieve "API design patterns"` -- gather context on API design thinking
- `/retrieve "project X decision"` -- find decision records for project X
