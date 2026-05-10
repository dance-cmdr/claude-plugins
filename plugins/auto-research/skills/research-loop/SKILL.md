---
name: research-loop
description: >
  Run an iterative Research-Review-Pivot verification loop on findings from any source.
  Analyzes PR review comments, spec feedback, or structured claims against a codebase.
  Each finding is verified through multi-round subagent cycling with adaptive scope.
  Triggers on "verify these findings", "research these comments", "check if this
  feedback is valid", "analyze review comments", "run research loop".
argument-hint: "<pr-url | findings-file-path | 'paste'>"
allowed-tools: Bash Read Grep WebFetch
---

# research-loop — Iterative Verification

Verify findings against a codebase through Research-Review cycling with 5 Whys depth.

## When to Use

- Processing PR review comments that need codebase verification
- Validating spec/plan review feedback against actual code
- Any structured list of claims that need evidence-based verification

## When NOT to Use

- You already know the answer (just respond directly)
- Findings are purely stylistic/preference (no codebase verification needed)
- Use `/generate` to create a niche-specific version of this skill

## Tool Access

`Bash` — required for `gh api` calls and `grep`/`find` during codebase exploration.
`Read` — file content verification at specific lines. `Grep` — pattern searching for
claim evidence. `WebFetch` — fetching external references or live documentation when
scope is wide. All four are minimum necessary for the verification loop to function.

## Prerequisites

Read the reference files before starting:
1. `${CLAUDE_SKILL_DIR}/references/loop-protocol.md` — state machine and decide logic
2. `${CLAUDE_SKILL_DIR}/references/agent-prompts.md` — subagent prompt templates
3. `${CLAUDE_SKILL_DIR}/references/grouping-strategies.md` — clustering strategies
4. `${CLAUDE_SKILL_DIR}/references/fan-out-prompt.md` — cluster agent prompt template

## Phase 1: Ingest Findings

Accept input from one of:

**GitHub PR URL**: Fetch comments via `gh api repos/{owner}/{repo}/pulls/{number}/comments`. Filter out bot comments and resolved threads.

**File path**: Read the file. Parse each bullet/numbered item as a finding.

**Pasted text**: Parse from conversation context.

For each finding, extract:
```
{ id, text, file_path (if referenced), line (if referenced), severity (inferred) }
```

## Phase 2: Group into Clusters

Select grouping strategy based on input source:
- PR comments → group by file (see `grouping-strategies.md`)
- Spec/plan feedback → group by theme
- If unclear, ask the user

Apply the strategy. Report clusters to the user before proceeding:
```
Grouped N findings into M clusters:
- Cluster 1: [theme/file] (N findings)
- Cluster 2: [theme/file] (N findings)
...
```

## Phase 3: Fan-out

Launch one Agent tool call per cluster **in a single message** (parallel fan-out). Each agent receives:

1. The cluster's findings
2. The full loop protocol (inlined from `loop-protocol.md`)
3. The appropriate agent prompts (inlined from `agent-prompts.md`)
4. Niche context (inferred from input source)
5. Starting scope level: `narrow`

Use the prompt template from `${CLAUDE_SKILL_DIR}/references/fan-out-prompt.md` to construct each agent's prompt. Inline the full protocol and agent prompts — agents need the complete instructions in their context.

## Phase 4: Consolidate Results

After all cluster agents return, merge their results.

## Phase 5: Output

Format results using tri-state + narrative structure:

```markdown
## Research Loop Results

**Source**: {{input source description}}
**Clusters processed**: {{N}}
**Total findings**: {{N}}
**Verdict breakdown**: {{N}} agreed, {{N}} disagreed, {{N}} uncertain

---

### AGREE: {{finding summary}}
{{Narrative: why the finding is correct, proposed fix or acknowledgement, evidence}}
**Evidence**: `{{file:line}}`

### DISAGREE: {{finding summary}}
{{Narrative: counter-claim with evidence why the finding's assumption is invalid}}
**Counter-evidence**: `{{file:line}}`

### UNCERTAIN: {{finding summary}}
{{Narrative: what we know, what's missing, what a spike would investigate}}
**Investigated**: `{{what was checked}}`
**Missing**: `{{what couldn't be determined}}`
```

If the niche has a specific output format (PR comments, etc.), use that instead.

## Handling Edge Cases

**No findings to process**: Report "no actionable findings found" and stop.

**Single finding**: Skip grouping, run the loop directly (no fan-out needed).

**All findings are GREEN in round 1**: Report immediately, don't force unnecessary rounds.

**User interrupts**: Report current state and partial results.
