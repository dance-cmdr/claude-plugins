---
name: spec
argument-hint: "[idea or feature name]"
description: >
  Transforms ideas, feature requests, or bug reports into structured specs
  through interactive codebase-grounded discovery. Generates testable acceptance
  criteria.
---

# spec — Specification Discovery

Transform a vague idea, feature request, or bug report into a structured, implementable specification through focused discovery on the existing codebase.

## Prerequisites

- Read the project adapter at `.claude/adapter.md` for project context, conventions, and file patterns.
- If `.claude/adapter.md` does not exist, STOP with: "No adapter found. Copy the template from `references/adapter-template.md` and customize for your project."
- Skim the project's feature tracker (if one exists — see adapter conventions) to understand existing features and the current phase.
- Check the project roadmap (if one exists — see adapter conventions) for where this work fits.

## When to Use

- Starting new work from an idea or requirement
- Requirements are unclear or incomplete
- The scope of a change needs definition before planning

## When to Skip

- You already have clear requirements and acceptance criteria
- The change is a one-line fix with obvious scope
- Jump to `/swarm-plan` or `/swarm` directly

## Process

### Phase 1: Orient (2-3 questions)

Understand the shape of the work:

1. **What**: "In one sentence, what problem are we solving or what feature are we adding?"
2. **Why**: "What's the motivation? (roadmap phase, user need, tech debt, bug)"
3. **Type**: Determine if this is a bug fix, new feature, refactoring, or infrastructure change.

Based on answers, determine which categories below are relevant. Bug fixes need fewer categories than new features.

### Phase 2: Codebase Exploration

Before asking more questions, **explore the existing code**:

1. Search for files related to the problem area (use Grep, Glob)
2. Read key files to understand current patterns and architecture
3. Check for existing tests that cover the area
4. Check the feature tracker for related features and their status (see adapter conventions)
5. Look at design system docs for relevant UX patterns (see adapter conventions)
6. Look at recent git history for related changes

This informs better questions and prevents asking about things the code already answers.

### Phase 3: Focused Deep Dive

Work through relevant categories. Ask 2-3 questions per category using AskQuestion. Skip categories that don't apply.

**A. Affected Areas**
- Which modules/files will this touch? (use adapter's file patterns)
- Are there downstream consumers that depend on current behavior?
- What existing tests cover this area?

**B. Acceptance Criteria**
- What does "done" look like? How do we verify it?
- What should happen in error cases?
- Are there edge cases to handle?

**C. UX and Design**
- Does this affect the UI or user interactions?
- Are there keybind or accessibility implications?
- Does the design system doc need updating? (see adapter conventions)

**D. Risk and Scope**
- What could go wrong? What's the blast radius?
- Is this containable in one session or does it need phased delivery?
- Are there migration or backwards-compatibility concerns?

**E. Out of Scope**
- What explicitly are we NOT changing?
- Are there related improvements to defer?

### Phase 4: Conflict Resolution

If conflicting requirements surface:

- Present the conflict explicitly with tradeoffs
- Ask the user to choose or explore alternatives
- Document the decision and rationale

### Phase 5: Completeness Check

Before generating the spec, verify:

- [ ] Problem statement is clear
- [ ] Affected areas identified (with file paths from adapter)
- [ ] Acceptance criteria are testable
- [ ] UX implications considered
- [ ] Risks acknowledged
- [ ] Scope boundaries drawn
- [ ] No unresolved "TBD" items

If anything is missing, go back and ask.

### Phase 6: Generate Spec

1. Summarize understanding and confirm with the user
2. Assign the next feature identifier if the project uses feature numbering (see adapter)
3. Write the spec using the template from `references/spec-template.md` to the spec output path (see adapter conventions, default: `docs/specs/YYYY-MM-DD-<name>.md`)

### Phase 7: Handoff

After spec is written:
- Update the feature tracker if the project uses one (see adapter conventions)
- "Spec saved to `[path]`. Run `/swarm-plan` to decompose this into tasks, or `/swarm` if the scope is small enough to implement directly."

## Guidance

- **Duration**: 5-15 questions for typical features. Bug fixes need fewer; new features need more.
- **Don't over-spec**: If the user says "I know what I want," respect that and keep it brief.
- **Spec as memory**: These docs become part of the project's institutional knowledge. Write them so a future agent can understand the context without re-asking.
