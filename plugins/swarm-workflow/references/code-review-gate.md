# Code Review Gate

Run this review as part of the inter-wave regression gate, after tests pass.
Evaluates all files changed in the completed wave across five axes.

---

## Five-Axis Review

For each changed file, evaluate:

### 1. Correctness
- Does the implementation match the spec/acceptance criteria?
- Are edge cases handled (the RED agent's tests should cover these, but verify)?
- Are there race conditions or state management issues?
- Do error paths return meaningful feedback?

### 2. Readability
- Are names descriptive and consistent with the codebase?
- Is control flow straightforward (no deeply nested conditionals)?
- Is the code organized logically (related functions grouped)?
- Would a new team member understand this without explanation?

### 3. Architecture
- Does it respect module boundaries (no reaching across layers)?
- Are abstractions at the right level (not too abstract, not too concrete)?
- Does dependency direction follow project conventions?
- Is there unnecessary coupling between components?

### 4. Security
- Are inputs validated at system boundaries?
- Are secrets kept out of code and logs?
- Are there injection vectors (SQL, command, template)?
- Is authentication/authorization checked where needed?

### 5. Performance
- Are there N+1 query patterns?
- Any unbounded operations (loading all records, no pagination)?
- Synchronous calls that should be async?
- Unnecessary re-renders or re-computations?

## Severity Classification

| Severity | Gate impact | Action |
|----------|-----------|--------|
| **Critical** | Blocks the gate | Must fix before next wave launches |
| **Important** | Flagged for wave fix | Should fix in current wave if possible |
| **Suggestion** | Informational | Log for later, don't block |

## Output

```markdown
## Code Review: Wave [N]

### Critical (gate blockers)
- [file:line] [description] — [axis]

### Important (should fix)
- [file:line] [description] — [axis]

### Suggestions
- [file:line] [description] — [axis]

### Positive
- [what was done well]
```

If no Critical findings: gate passes.
If Critical findings exist: gate fails, fix agent targets the specific issues.
