# Output Formats

## Available Output Formats

Each niche template defines its preferred output format. The generator uses this reference to help users choose and customize their output.

## Format: PR Comments

**Best for**: GitHub PR reviews, GitLab MR reviews, code review responses

Produces one comment per cluster (grouped by file). Posted via `gh api` or presented for user approval.

```markdown
**Research Summary: `{file_path}`**

> {original reviewer comment}

**{AGREE | DISAGREE | UNCERTAIN}**: {verdict narrative}

---
```

**Delivery method**: `gh api repos/{owner}/{repo}/pulls/{number}/comments --method POST`

**Considerations**:
- Respect rate limits (pause between posts if many clusters)
- Always present for user approval before posting (never auto-post)
- Collapse lengthy evidence into `<details>` blocks

## Format: Markdown Report

**Best for**: Spec reviews, plan reviews, internal documentation

Produces a single markdown file with executive summary, findings by theme, and action items.

```markdown
# {Title} Analysis

## Executive Summary
{2-3 sentences}

## Findings
### {VERDICT}: {summary}
{narrative}

## Action Items
- [ ] {specific action}

## Uncertain Items
| Finding | Known | Missing |
```

**Delivery method**: Write to file (user specifies path) or output to conversation.

## Format: Annotated Plan

**Best for**: Plan reviews, implementation feedback

Produces a plan assessment with feasibility rating, finding analysis, and suggested adjustments.

```markdown
# Plan Review Analysis

## Feasibility Assessment
{assessment with confidence level}

## Finding Analysis
### {summary}
> {original concern}
**{VERDICT}**: {narrative}
**Impact on plan**: {adjustment or "no change"}

## Plan Adjustments
1. {adjustment with rationale}
```

**Delivery method**: Write to file or output to conversation.

## Format: Inline Suggestions

**Best for**: Code-level feedback that maps directly to file:line locations

Produces GitHub suggestion blocks that can be applied directly.

````markdown
```suggestion
{corrected code}
```
{Explanation of why this change is needed}
````

**Delivery method**: PR review comments with suggestion blocks.

**Considerations**:
- Only use when the fix is a clear code change (not design decisions)
- Include explanation below the suggestion block
- Group related suggestions into a single review

## Format: Custom

Users can define their own output format during generation. The generator will ask:
1. What structure should the output have? (sections, tables, lists)
2. Where should it be delivered? (file, conversation, API)
3. What metadata should be included? (dates, authors, confidence levels)

The custom format is written into the generated skill's output phase.
