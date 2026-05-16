---
name: swarm
argument-hint: "<plan-file> [task-ids...]"
description: >
  Parallel task executor with separated test agents (RED) and dev agents (GREEN),
  inter-wave regression gates, and automatic /validate chaining on completion.
  Use with `/swarm <plan-file>`.
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            You are checking whether a swarm execution phase is complete.

            Examine this assistant message. Does it indicate that ALL planned tasks
            are finished, integrated, and the regression gate has passed? Look for:
            - "all tasks complete", "all N tasks implemented"
            - "final regression green", "regression gate passed"
            - "ready for validation", "run /validate"
            - An execution summary with no remaining or blocked tasks

            If swarm execution IS complete, respond with:
            {"decision": "block", "reason": "Swarm execution complete. Read the project adapter at .claude/adapter.md, then read and execute the validate skill at ${CLAUDE_PLUGIN_ROOT}/skills/validate/SKILL.md to run broad validation and phase closure."}

            If execution is NOT complete (partial progress, asking a question, debugging, waiting for user input, retrying tasks), respond with:
            {}

            The message to examine:
            $ARGUMENTS
          timeout: 15
---

# Swarm Executor — Parallel TDD with Test/Dev Agent Separation

You are an Orchestrator. Parse plan files and execute tasks in parallel waves using **separated test and dev agents**. For each task: a test agent writes failing tests (RED), then a dev agent implements until green (GREEN). Between waves, run regression gates. After all waves, perform integration fixes and signal completion.

## Prerequisites

- Read the project adapter at `.claude/adapter.md` for test commands, lint, conventions, and regression gate commands.
- If `.claude/adapter.md` does not exist, STOP with: "No adapter found. Copy the template from `references/adapter-template.md` and customize for your project."
- A plan file must exist (produced by `/swarm-plan`).

## Model Routing

| Agent Role | Model | Rationale |
|------------|-------|-----------|
| **Orchestrator** (you) | opus | Judgment calls, validation, conflict resolution |
| **Test Agent** (RED) | opus | Deep reasoning about acceptance criteria, edge cases |
| **Dev Agent** (GREEN) | sonnet | Fast, focused implementation — tests define the contract |
| **Design Gate** (optional) | opus | Visual review of CSS/layout changes |

## Process

### Step 1: Parse Plan

Extract from user request:
1. **Plan file**: The markdown plan to read
2. **Task subset** (optional): Specific task IDs to run

Read and parse the plan:
1. Find task subsections (e.g., `### T1:` or `### Task 1.1:`)
2. For each task, extract: Task ID, name, depends_on, files, test_files, test_type, description, acceptance_criteria, validation command
3. Build dependency graph and calculate waves

If no subset provided, run the full plan.

### Step 2: Execute Waves

For each wave, launch all unblocked tasks in parallel. A task is unblocked when all IDs in its `depends_on` are complete AND the previous wave's regression gate passed.

**For each task, execute two sequential agents using the prompts from `references/swarm-agent-prompts.md`:**

1. **Phase A: Test Agent (RED)** — Launch with `model: opus`. Inject task context into the RED agent template. Validate RED evidence before proceeding.
2. **Phase B: Dev Agent (GREEN)** — Launch with `model: sonnet`. Inject task context into the GREEN agent template. Validate GREEN evidence before marking complete.

### Step 3: Inter-Wave Regression Gate

After ALL tasks in a wave complete:

1. Run the regression gate command from the adapter.
2. If regression fails: identify breaking task(s), launch fix agent (sonnet), re-run until green.
3. **Code review gate**: Run the review from `references/code-review-gate.md` against all files changed in this wave. If Critical findings exist, launch a fix agent (sonnet) targeting the issues before proceeding.
4. If CSS/layout files were touched: run design gate (if web-designer skill installed).
5. Proceed to next wave.

**Do NOT launch the next wave until regression is green.**

### Step 4: Final Integration Pass

After all waves complete:

1. **Reconcile parallel conflicts**: duplicate files, naming drift, import conflicts.
2. **Cross-task integration**: verify dependent tasks integrate correctly.
3. **Add integration tests** if task-level RED coverage missed cross-task behavior.
4. **Run full regression** using the adapter's full test matrix command.
5. Fix any failures. Re-run until green.

### Step 5: Completion Signal

When all tasks are complete, integrated, and regression is green, output the execution summary (see `references/execution-summary.md` for the template) and announce:

"All N tasks complete across M waves. Final regression green. Proceeding to validation."

The `Stop` hook will detect this and chain into `/validate`.

## Error Handling

- **Test agent can't write meaningful tests**: Acceptance criteria may be too vague. Escalate to user.
- **Dev agent can't make tests pass after 2 attempts**: Escalate — the test may be wrong.
- **Regression gate fails**: Identify the breaking task, fix it, re-run.
- **File conflict between parallel tasks**: Resolve in the integration pass.
- **Task subset not found**: List available task IDs from the plan.

## Example Usage

```
/swarm auth-plan.md
/swarm ./plans/phase-a-plan.md T1 T2 T4
/swarm undo-redo-plan.md --tasks T3 T7
```
