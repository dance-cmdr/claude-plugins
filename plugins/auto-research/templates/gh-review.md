# GitHub PR Review Template

## Niche Configuration

```yaml
niche: gh-review
input_source: gh_pr_comments
output_format: pr_comments
grouping_strategy: by_file
exploration_scope: adaptive
verification_tools: grep, read, git_log, test_runner
```

## Input Parsing

Fetch PR comments:
```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

Parse each comment into a finding:
- `file_path`: from `path` field
- `line`: from `line` / `start_line` fields
- `text`: from `body` field
- `severity`: infer from tone (suggestion vs demand vs question)
- `author`: from `user.login`

**Filter out**: bot comments (user.type == "Bot"), resolved conversation threads, approval-only reviews with no inline comments.

**Severity inference**:
- "must", "should not", "bug", "wrong" → MAJOR
- "consider", "might", "suggestion", "nit" → MINOR
- Questions without assertions → MINOR (still investigate)

## Niche Context (for Research Agent)

```
You are analyzing code review feedback on a GitHub pull request. A reviewer
has identified potential issues in the changed code. Your job is to determine
whether each comment identifies a real problem, and if so, what the correct
fix is.

Key considerations for PR reviews:
- The reviewer only sees the diff, not the full file context
- The reviewer may reference patterns from other projects that don't apply here
- Some comments may be outdated if the PR was updated after the review
- "Nit" comments are valid but low priority — still verify factual claims

Explore: the referenced files (full content, not just diff), their test files,
direct callers, and the PR diff itself (git diff against base branch).
```

## Niche Context (for Review Agent)

```
You are verifying claims about code in a pull request review context.

Common false positives in PR reviews:
- Reviewer saw only the diff and missed surrounding context
- Reviewer references behavior that was already addressed elsewhere in the PR
- Reviewer suggests a pattern that conflicts with this project's conventions
- Reviewer's concern is valid in general but handled by a different mechanism

When checking claims, also verify:
- Is the referenced code actually IN the PR diff, or is it pre-existing?
- Does the test suite already cover the concern?
- Is there a project convention that addresses this?
```

## Niche Context (for Pivot Agent)

```
Previous approaches focused on verifying the reviewer's claims directly against
the current code. Consider instead:
- Whether the reviewer is thinking of a DIFFERENT version of the code (check git log)
- Whether the PR description or commit messages explain choices the reviewer questions
- Whether the concern is about a transient state that will be resolved in a follow-up
- Whether adjacent PRs or branches address the concern
```

## Output Format

For each cluster (grouped by file), produce a PR comment:

```markdown
**Research Summary: `{file_path}`**

{For each finding in cluster:}

> {original reviewer comment, quoted}

**{AGREE | DISAGREE | UNCERTAIN}**: {1-2 sentence verdict with evidence}
{If AGREE: "Suggested fix: {description}"}
{If DISAGREE: "Counter-evidence: `{file:line}` shows {explanation}"}
{If UNCERTAIN: "Needs spike: {what we'd need to investigate further}"}

---
```

## Scope Escalation (PR-specific)

- **Narrow**: The file referenced in the comment + its immediate diff context
- **Medium**: Referenced file + its test file + direct imports + callers within PR
- **Wide**: Full repo search + git log + base branch comparison + CI config
