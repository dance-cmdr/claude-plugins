# Plan Review Template

## Niche Configuration

```yaml
niche: plan-review
input_source: markdown_file
output_format: annotated_plan
grouping_strategy: by_theme
exploration_scope: adaptive
verification_tools: grep, read, git_log
```

## Input Parsing

Read the plan review file (markdown). Parse each finding as:
- Concerns about feasibility ("can we actually do X?")
- Questions about approach ("why not Y instead?")
- Suggestions for alternatives ("consider Z")
- Identified risks or gaps ("what about W?")
- Order/dependency concerns ("X should happen before Y")

Category markers (if present): [FEASIBILITY], [APPROACH], [RISK], [GAP], [ORDER], [SCOPE]

## Niche Context (for Research Agent)

```
You are analyzing feedback on an implementation plan. A reviewer has raised
concerns about whether the plan is feasible, complete, or optimal. Your job
is to verify claims about the codebase that bear on these concerns.

Key considerations for plan reviews:
- Plans reference files to modify — verify those files exist and are structured as assumed
- Plans assume dependency ordering — verify actual code dependencies match
- Plans estimate effort — check code complexity (LOC, coupling, test coverage)
- Plans may miss existing utilities — search for reusable code the plan could leverage

Explore: files the plan proposes to modify, their dependencies, test infrastructure,
and git history for similar past changes (how long did they take? what broke?).
```

## Niche Context (for Review Agent)

```
You are verifying claims about an implementation plan against the codebase.

Verify:
- FILE ASSUMPTIONS: Do referenced files exist? Are they structured as the plan assumes?
- DEPENDENCY ORDER: Does the plan's sequence match actual code dependencies?
- EFFORT ESTIMATES: Is the plan's scope reasonable given code complexity?
- MISSED UTILITIES: Are there existing functions/patterns the plan could reuse?
- RISK ASSESSMENT: Do the identified risks match what git history shows?

A claim is RED if:
- The plan references a file/function/API that doesn't exist or was moved
- The plan's dependency ordering would cause circular imports or break builds
- The plan misses a critical file that must also be modified
- An "existing utility" the plan claims to leverage doesn't do what's assumed
```

## Niche Context (for Pivot Agent)

```
Previous approaches verified the plan's assumptions against current code.
Consider instead:
- Whether the plan's GOALS could be achieved via a completely different approach
- Whether recent changes (last 2 weeks of git log) have shifted the landscape
- Whether the plan conflicts with work happening on other branches
- Whether the plan's phasing could be reordered to reduce risk
- Whether a smaller proof-of-concept would resolve the reviewer's concerns
```

## Output Format

Produce an annotated plan assessment:

```markdown
# Plan Review Analysis

**Plan**: {plan title or filename}
**Reviewer**: {if known}
**Date**: {today}
**Findings**: {N} total — {N} agreed, {N} disagreed, {N} uncertain

## Feasibility Assessment

{2-3 sentences: is this plan executable as written?}

**Confidence**: HIGH | MEDIUM | LOW
**Recommended action**: Proceed | Revise | Spike first

## Finding Analysis

### {Finding 1: summary}

> {original reviewer concern}

**{AGREE | DISAGREE | UNCERTAIN}**

{Narrative: what we found in the code, whether the concern is valid}

**Evidence**: `{file:line references}`
**Impact on plan**: {how the plan should be adjusted, or "no change needed"}

---

### {Finding 2: summary}
...

## Plan Adjustments (if any findings AGREED)

1. {Specific change to the plan, with rationale}
2. {Another adjustment}

## Unresolved Questions (UNCERTAIN items)

| Question | What we checked | What's needed |
|----------|----------------|---------------|
| ... | ... | ... |

## Missed Opportunities

{Any existing utilities, patterns, or shortcuts the plan didn't mention but could leverage}
- `{file:line}`: {what it does and how the plan could use it}
```

## Scope Escalation (Plan-specific)

- **Narrow**: Files explicitly named in the plan + the plan document itself
- **Medium**: Named files + their dependencies + test files + related documentation
- **Wide**: Full repo search + git log (last 30 days) + other branches + CI/CD config
