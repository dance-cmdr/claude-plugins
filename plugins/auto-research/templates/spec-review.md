# Spec Review Template

## Niche Configuration

```yaml
niche: spec-review
input_source: markdown_file
output_format: markdown_report
grouping_strategy: by_theme
exploration_scope: adaptive
verification_tools: grep, read, webfetch, git_log
```

## Input Parsing

Read the spec review file (markdown). Parse each finding as:
- Numbered or bulleted items
- Category markers if present: [DESIGN], [IMPL], [NAMING], [SCOPE], [RISK], [TEST]
- Section headers indicate theme grouping
- Inline quotes indicate the spec text being challenged

If the input is unstructured prose, split by paragraph — each paragraph raising a distinct concern becomes one finding.

## Niche Context (for Research Agent)

```
You are analyzing review feedback on a technical specification or RFC. A reviewer
has raised concerns about the proposed design. Your job is to determine whether
each concern is valid given the existing codebase, and whether the spec adequately
addresses it or needs revision.

Key considerations for spec reviews:
- Specs describe FUTURE state, not current state — some things won't exist yet
- Concerns about feasibility should be checked against current architecture
- Concerns about conflicts should be checked against existing patterns
- Concerns about scope should be checked against related specs/roadmap

Explore: existing implementations of similar patterns, related documentation,
test coverage for affected areas, and any referenced prior art.
```

## Niche Context (for Review Agent)

```
You are verifying claims about a technical specification against the codebase.

Key distinction: the spec describes intended changes, so "this doesn't exist"
may be intentional (it's being proposed). Verify:
- Claims about CURRENT state: grep/read to confirm
- Claims about CONFLICTS: check if the proposed change actually conflicts
- Claims about FEASIBILITY: check if dependencies/APIs support the approach
- Claims about PRIOR ART: check if referenced patterns actually exist

A claim is RED if:
- It asserts something about current code that is demonstrably false
- It claims a conflict that doesn't actually exist
- It claims infeasibility but the infrastructure clearly supports it
```

## Niche Context (for Pivot Agent)

```
Previous approaches checked the spec's claims against current code state.
Consider instead:
- Whether the reviewer is applying constraints from a different system/project
- Whether the spec references an external standard or RFC that defines the approach
- Whether the concern is about migration path rather than end state
- Whether there's a simpler design that sidesteps the reviewer's concerns entirely
- Industry patterns or library documentation that validate or invalidate the approach
```

## Output Format

Produce a markdown report:

```markdown
# Spec Review Analysis

**Spec**: {spec title or filename}
**Reviewer**: {if known}
**Date**: {today}
**Findings**: {N} total — {N} agreed, {N} disagreed, {N} uncertain

## Executive Summary

{2-3 sentences: overall assessment of review feedback validity}

## Findings by Theme

### {Theme 1: e.g., "Architecture Concerns"}

| # | Finding | Verdict | Confidence |
|---|---------|---------|------------|
| 1 | {summary} | AGREE | HIGH |
| 2 | {summary} | DISAGREE | MEDIUM |

#### Finding 1: {summary}
> {original reviewer text}

**AGREE**: {narrative with evidence}
**Suggested spec revision**: {what to change in the spec}

#### Finding 2: {summary}
> {original reviewer text}

**DISAGREE**: {narrative with counter-evidence}
**Why the spec is correct**: {explanation}

---

### {Theme 2: e.g., "Testing Gaps"}
...

## Action Items

- [ ] {Specific spec revision needed}
- [ ] {Spike needed for uncertain findings}

## Uncertain Items (need spike)

| Finding | What we know | What's missing |
|---------|-------------|----------------|
| ... | ... | ... |
```

## Scope Escalation (Spec-specific)

- **Narrow**: Files/modules explicitly named in the spec + the spec document itself
- **Medium**: Named files + their tests + related documentation + similar patterns in codebase
- **Wide**: Full codebase search + external docs (WebFetch for referenced standards) + git history of related areas
