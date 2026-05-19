# Spec Template

Template for structured specifications produced by `/spec`.

```markdown
# [Title] Specification

**Feature(s)**: [identifier if applicable]
**Phase**: [which roadmap phase, if applicable]
**Date**: YYYY-MM-DD

## Problem Statement
[What we're solving, current pain, why now]

## Affected Areas
[Files, modules, and systems involved — with paths from adapter]

## Requirements
### Must Have (P0)
- [Requirement with testable acceptance criteria]

### Should Have (P1)
- [Requirement with testable acceptance criteria]

## User Journey
[Step-by-step user interaction]

## Acceptance Criteria
- [ ] [Specific, verifiable criterion]

## Test Plan
- **Pure function tests**: [what logic to extract and test]
- **Component tests**: [what to render and assert]
- **Integration tests**: [API/database tests]
- **E2E test**: [user journey to automate]

## Technical Approach
[High-level approach based on codebase exploration]

## Risks
- [Risk with mitigation]

## Out of Scope
- [What we're explicitly deferring]

## Open Questions
- [Anything to resolve during planning/implementation]
```
