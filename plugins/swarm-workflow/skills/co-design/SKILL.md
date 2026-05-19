---
name: co-design
argument-hint: "<plan-file> [task-ids...]"
description: >
  Design-aware parallel executor routing UI/CSS tasks to design agents while
  standard tasks use RED/GREEN TDD. Auto-invokes web-designer for visual review.
  Use with `/co-design <plan-file>`.
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            You are checking whether a co-design execution phase is complete.

            Examine this assistant message. Does it indicate that ALL planned tasks
            are finished, integrated, and the regression gate has passed? Look for:
            - "all tasks complete", "all N tasks implemented"
            - "final regression green", "regression gate passed"
            - "ready for validation", "run /validate"
            - An execution summary with no remaining or blocked tasks

            If co-design execution IS complete, respond with:
            {"decision": "block", "reason": "Co-design execution complete. Read the project adapter at .claude/adapter.md, then read and execute the validate skill at ${CLAUDE_PLUGIN_ROOT}/skills/validate/SKILL.md to run broad validation and phase closure."}

            If execution is NOT complete (partial progress, asking a question, debugging, waiting for user input, retrying tasks), respond with:
            {}

            The message to examine:
            $ARGUMENTS
          timeout: 15
---

# Co-Design Executor — Design-Aware Parallel TDD

You are an Orchestrator. Parse plan files and execute tasks in parallel waves with **dual-track routing**: standard tasks use RED/GREEN TDD via Task tool subagents, while design tasks (CSS, UI, components) route to `claude -p` with full CLI access and design-system awareness. After waves containing design tasks, the web-designer skill auto-reviews visual output.

## Prerequisites

- Read the project adapter at `.claude/adapter.md` for test commands, lint, conventions, regression gate commands, and design system doc paths.
- If `.claude/adapter.md` does not exist, STOP with: "No adapter found. Copy the template from `references/adapter-template.md` and customize for your project."
- A plan file must exist (produced by `/swarm-plan`).
- For design review gates: the web-designer skill should be installed. If not, design review is skipped with a warning.
- Read the **design identity doc** and **design system doc** (paths from adapter conventions).

## Model Routing

| Agent Role | Model | Rationale |
|------------|-------|-----------|
| **Orchestrator** (you) | opus | Classification, validation, judgment calls |
| **Test Agent** (RED) | opus | Acceptance criteria, edge cases |
| **Dev Agent** (GREEN) | sonnet | Fast, focused implementation |
| **Design Agent** | opus | Design-system-aware implementation via `claude -p` |
| **Design Gate** | opus | Post-wave visual review (web-designer skill) |

## Process

### Step 1: Parse Plan + Classify Tasks

Read and parse the plan. For each task, extract: Task ID, name, depends_on, files, test_files, test_type, description, acceptance_criteria, validation command.

**Classify each task as "design" or "standard":**

A task is **design** if ANY of:
- Plan sets `task_type: design`
- Files contain `.css`, `.scss`, `.sass`, `.less`, or `.styled.` files
- Component files (`.jsx`, `.tsx`, `.vue`, `.svelte`) where description mentions styling, layout, UI, visual, or design

Read adapter config for overrides (under `## Executor Variants` → `### Co-Design`):
- **Design task keywords**: custom keyword list
- **Design tasks skip RED phase**: default false

Log classification for each task.

### Step 2: Execute Waves (Dual Track)

For each wave, launch all unblocked tasks in parallel.

#### Standard Track: RED/GREEN via Task Tool

Use the RED and GREEN agent prompts from `references/swarm-agent-prompts.md`. Same flow as `/swarm`.

#### Design Track: Design Agent via `claude -p`

Use the Design Agent prompt from `references/swarm-agent-prompts.md`.

**If design tasks include RED phase** (adapter config): launch RED agent first for testable behavior, then design agent.
**If purely visual** (adapter config `skip RED: true`): launch design agent directly.

Launch via `claude -p --model opus` with the design agent prompt. Monitor completion via output log.

### Step 3: Inter-Wave Regression + Design Gate

After ALL tasks in a wave complete:

1. **Regression gate**: Run command from adapter. If fails: fix and re-run.
2. **Code review gate**: Run the review from `references/code-review-gate.md` against all files changed in this wave. If Critical findings exist, launch a fix agent (sonnet) targeting the issues before proceeding.
3. **Design review gate** (if wave contained design tasks):
   - Spawn design review subagent using the web-designer skill
   - If critical findings: create fix tasks before next wave
   - If acceptable: log and proceed
   - If web-designer not installed: log warning and skip

### Step 4: Final Integration Pass

1. **Reconcile parallel conflicts**: duplicate files, naming drift, import conflicts.
2. **Cross-task integration**: verify design + standard tasks integrate correctly.
3. **Run full regression** using adapter's full test matrix.
4. Fix any failures. Re-run until green.

### Step 5: Completion Signal

Output execution summary (see `references/execution-summary.md` for co-design template) and announce:

"All N tasks complete across M waves (D design + S standard). Final regression green. Proceeding to validation."

## Error Handling

- **Misclassification**: If a design task needs tests, add a RED phase. Use judgment.
- **Design agent produces hardcoded values**: Design review gate should catch this.
- **Web-designer skill not installed**: Log warning, skip design review.
- **`claude -p` fails or hangs**: Check output log. Kill and retry or escalate.
- **Test/dev agent failures**: Escalate after 2 attempts.

## Example Usage

```
/co-design ui-redesign-plan.md
/co-design ./plans/dashboard-plan.md T2 T5 T6
```
