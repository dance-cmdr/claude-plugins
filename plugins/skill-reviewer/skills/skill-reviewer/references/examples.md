# Skill Review Examples

Before/after pairs illustrating common review findings and fixes.

## Weak vs Strong Description

### Before (weak)
```yaml
---
name: test-helper
description: Helps with testing.
---
```

Problem: Claude can't distinguish this from any other testing tool. No trigger
phrases, no specificity about what kind of testing or when to activate.

### After (strong)
```yaml
---
name: test-helper
description: >-
  Generates pytest test scaffolds for Python modules. Activates when the user
  asks to "write tests for", "add test coverage to", or "scaffold tests" for
  a Python file. Follows the project's existing test conventions in tests/.
---
```

Why it works: Third person, verb-led, specific trigger phrases, scoped to Python
and pytest, references project conventions.

---

## Bloated vs Lean SKILL.md

### Before (bloated — 4,000+ words in SKILL.md)
```markdown
---
name: api-reviewer
description: Reviews API endpoints.
---

# API Review Guide

## What is REST

REST stands for Representational State Transfer...
[500 words explaining REST]

## HTTP Methods

GET is used for retrieving resources...
[300 words explaining HTTP methods]

## Our API Conventions

### Naming
- Use kebab-case for URLs
- Use camelCase for JSON fields
[...2,000 words of conventions...]

## Review Process
1. Check endpoint naming
2. Validate response format
[...800 words of review steps...]

## Examples
[...500 words of examples...]
```

### After (lean — 800 words in SKILL.md, rest in references/)
```markdown
---
name: api-reviewer
description: >-
  Reviews API endpoint definitions for adherence to project REST conventions.
  Activates when reviewing PR changes to files in routes/ or api/ directories,
  or when the user asks to "review API", "check endpoints", or "validate API
  conventions".
---

# API Review Guide

Review API endpoints against project conventions.

## When to Activate

- PR changes files in `routes/` or `api/`
- User asks to review API changes

## When NOT to Activate

- Frontend component changes
- Database migration review
- General code review (not API-specific)

## Review Process

1. Read the changed endpoint files
2. Check naming against `references/conventions.md`
3. Validate response format
4. Post structured review

See `references/conventions.md` for the full naming and format rules.
See `references/examples.md` for correct vs incorrect endpoint patterns.
```

Why it works: SKILL.md drives the workflow. Reference material lives in
`references/` and is loaded only when Claude reaches that step.

---

## Second Person vs Imperative

### Before
```markdown
You should validate that the frontmatter contains all required fields.
You need to check that the name is kebab-case.
You must ensure the description is under 200 characters.
```

### After
```markdown
Validate that the frontmatter contains all required fields.
Check that the name is kebab-case.
Ensure the description is under 200 characters.
```

Why it works: Imperative form is direct instruction. Second person reads as
suggestion or advice, which Claude may treat as optional.

---

## Missing vs Present Resource References

### Before (orphaned reference)
```markdown
## Review Process

1. Read the skill file
2. Check against our standards (see `references/standards.md`)
3. Post review
```

But `references/standards.md` doesn't exist. Claude tries to read it, gets an
error, and either halts or proceeds without the standards.

### After (complete references)
```markdown
## Review Process

1. Read the skill file
2. Check against standards in `references/standards.md`
3. Validate patterns using `references/examples.md`
4. Post review
```

Both files exist and contain the referenced content. Claude loads them at the
right step and uses the content in its review.

---

## Review Output Example

A complete review for a new skill might look like:

```markdown
## Skill Review: deploy-helper

Well-structured skill with clear activation boundaries. Two issues to address
before merge.

### Suggestions

1. *[Blocker]* Missing `disable-model-invocation: true` — this skill runs
   `kubectl apply` which has production side effects. Add the frontmatter
   field to prevent automatic invocation.

2. *[Minor]* Description is 45 characters ("Helps deploy services"). Expand
   to include trigger phrases like "deploy to staging", "push to production",
   "run deployment".

<details>
<summary><strong>Detailed Assessment</strong></summary>

| Criterion | Status | Notes |
|-----------|--------|-------|
| Concise (no known-concept explanations) | pass | No unnecessary explanations |
| Third person description | pass | "Helps deploy services" |
| Appropriate degrees of freedom | pass | Clear deployment steps |
| Progressive disclosure (<500 lines, refs/) | pass | 300 lines, config in refs/ |
| Actionable workflows | pass | Step-by-step deployment process |
| Single recommended pattern | pass | One deployment workflow |
| Description includes what + when | warn | Missing trigger phrases |
| Frontmatter (name + description) | pass | Both present and valid |
| Activation boundaries (when / when not) | pass | Both sections present |
| Real codebase examples | pass | Uses actual k8s manifests |
| Appropriate scope (one domain) | pass | Focused on deployment only |

</details>
```
