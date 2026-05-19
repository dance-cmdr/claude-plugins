---
name: retrieve
description: >
  On-demand knowledge retrieval across all linked vaults using a 5-step strategy:
  index lookup, full-text grep, link traversal, backlink scan, and recency weighting.
  Searches personal knowledge AND all domain vaults. Respects vault boundaries in
  link traversal.
argument-hint: "[query] [--vault name]"
allowed-tools: Bash Read Grep Glob
---

# retrieve -- Knowledge Retrieval

Retrieve relevant notes from your second-brain using a multi-step search strategy
that combines text matching with graph traversal across all linked domain vaults.

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
Then read `{vault_path}/.vault-config.md` to get:
- `knowledge_vaults` -- list of linked domain vaults
- `personal_knowledge_dir` -- path to personal knowledge

## Search Scope

By default, search ALL knowledge paths:
- `{vault_path}/{personal_knowledge_dir}/` (personal cross-domain notes)
- Each vault in `knowledge_vaults` via its symlink path

If `--vault name` is provided, restrict search to that specific vault only.

Never search `self/` or `ops/` — those are operational, not knowledge.

## Retrieval Strategy

Execute these 5 steps in order. Stop early if sufficient context is found.

### Step 1: Index Lookup

Search for index files across all knowledge paths:

```bash
BRAIN="{vault_path}"
# Search each vault's indexes directory
for VAULT in "$BRAIN"/knowledge/*/; do
  find "$VAULT" -path "*/indexes/*" -name "*.md" -exec grep -il "{query}" {} \;
done
```

For each matching index file, extract `[[wiki-link]]` entries from lines containing
the query term. Index notes are high-signal curated entry points.

### Step 2: Full-Text Grep

Search all knowledge paths for notes containing query terms:

```bash
grep -ril --include="*.md" "{query}" "{vault_path}/knowledge/" | grep -v "/\."
```

Exclude hidden directories. Get matching lines plus 2 lines of context for the top
results.

If total notes across vaults >200, limit grep results to 10 before traversal.

### Step 3: Link Traversal (1-2 hops)

For the top 5 matches from steps 1-2:

1. Extract all outgoing `[[wiki-links]]` from the note
2. Resolve links by searching for matching filenames across all knowledge paths
3. Read linked notes (frontmatter + first 3 lines only for efficiency)
4. For the top 3 most relevant linked notes, follow one more hop

**Cross-vault linking**: Personal knowledge notes may link to domain vault notes.
Follow these links during traversal. Domain vault notes only link within their
own vault — don't follow links that would cross vault boundaries from domain notes.

### Step 4: Backlink Scan

For the top 5 matches, find notes that link TO them:

```bash
grep -rl "\[\[{title}\]\]" "{vault_path}/knowledge/" | grep -v "/\."
```

Backlinks reveal how other notes reference the matched content. Note which vault
each backlink comes from — cross-vault references from personal/ are especially
interesting as they represent the user's synthesis.

### Step 5: Recency Weighting

Sort and rank all collected results:

1. Index matches (highest signal -- curated by the user)
2. Personal knowledge matches (cross-domain synthesis — high value)
3. Recent full-text matches (modified within last 30 days)
4. Older full-text matches
5. Graph-connected notes (reached via links/backlinks)

Use file modification time for recency sorting (`stat -f %m` on macOS, `stat -c %Y` on Linux).

## Token Efficiency Rules

- Read full content only for top 5 direct matches
- For graph-connected notes (hops), read only frontmatter + first 3 lines
- Cap total notes read at 20
- If total notes >200, limit grep to 10 results before traversal

## Output Format

Present results in this structure:

```markdown
## Retrieved: "{query}"

### Direct matches (N)
1. **[[Note Title]]** ({vault-name}) -- excerpt of matching content
   Links to: [[x]], [[y]]
   Linked from: [[z]]

2. **[[Another Note]]** (personal) -- excerpt
   Links to: [[a]]
   Linked from: [[b]], [[c]]

### Graph context (via links)
- [[Direct Match]] ({vault}) -> [[1-hop Note]] -> [[2-hop Note]]
- [[Another Match]] (personal) -> [[Related Idea]] ({vault})

### Vault distribution
- {vault-a}: {N} results
- {vault-b}: {N} results
- personal: {N} results

### Suggestions
- Related indexes: [[_index_topic]]
- Try also: "alternative search term"
- Narrow with: `/retrieve "query" --vault {name}`
```

## Usage Examples

- `/retrieve "spaced repetition"` -- search all vaults for spaced repetition
- `/retrieve "fileserver boot" --vault lizard-brain` -- search only PA domain
- `/retrieve "API design patterns"` -- cross-domain search for API thinking
- `/retrieve "project X decision"` -- find decision records anywhere
