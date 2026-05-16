---
name: super-swarm
argument-hint: "<plan-file> [task-ids...]"
description: >
  Rolling pool executor with up to 12 concurrent RED/GREEN agent pairs. Tasks
  launch when dependencies are satisfied — no wave waiting. Use with
  `/super-swarm <plan-file>`.
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            You are checking whether a super-swarm execution phase is complete.

            Examine this assistant message. Does it indicate that ALL planned tasks
            are finished, integrated, and the regression gate has passed? Look for:
            - "all tasks complete", "all N tasks implemented"
            - "final regression green", "regression gate passed"
            - "ready for validation", "run /validate"
            - An execution summary with no remaining or blocked tasks

            If super-swarm execution IS complete, respond with:
            {"decision": "block", "reason": "Super-swarm execution complete. Read the project adapter at .claude/adapter.md, then read and execute the validate skill at ${CLAUDE_PLUGIN_ROOT}/skills/validate/SKILL.md to run broad validation and phase closure."}

            If execution is NOT complete (partial progress, asking a question, debugging, waiting for user input, retrying tasks), respond with:
            {}

            The message to examine:
            $ARGUMENTS
          timeout: 15
---

# Super-Swarm Executor — Rolling Pool TDD with Test/Dev Agent Separation

You are an Orchestrator. Parse plan files and execute tasks using a **rolling pool** of up to 12 concurrent RED/GREEN agent pairs. Unlike wave-based execution, tasks launch as soon as dependencies are satisfied and a pool slot is available — no waiting for an entire wave to complete. Regression gates run periodically rather than at wave boundaries.

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
3. Build dependency graph and **ready queue** (tasks whose depends_on are empty or already complete)

If no subset provided, run the full plan.

### Step 2: Initialize Rolling Pool

Read pool configuration from adapter (under `## Executor Variants` → `### Super-Swarm`):
- **Max concurrent agents**: default 12
- **Regression gate frequency**: default every 4 completed tasks

Initialize tracking:
- `active_slots`: currently executing RED/GREEN pairs (max = pool size)
- `completed_count`: total tasks completed
- `completed_since_last_gate`: counter, resets after each regression gate
- `ready_queue`: tasks whose dependencies are all satisfied but not yet launched

### Step 3: Rolling Pool Execution

**Loop until all tasks are complete or all remaining tasks are blocked:**

1. **Fill pool**: While `active_slots < max_concurrent` AND `ready_queue` is not empty:
   - Dequeue next task, launch its RED/GREEN pair (see `references/swarm-agent-prompts.md`), increment `active_slots`

2. **Wait for any completion**: When a RED/GREEN pair finishes:
   - Validate GREEN evidence (tests pass, lint clean)
   - If validation fails, retry dev agent (up to 2 attempts) or escalate
   - Mark task complete, decrement `active_slots`
   - Increment `completed_count` and `completed_since_last_gate`
   - **Refresh ready queue**: check all pending tasks — any whose dependencies are now all complete get added

3. **Periodic regression gate**: If `completed_since_last_gate >= gate_frequency`:
   - Wait for all in-flight tasks to finish their current cycle
   - Run regression gate command from adapter
   - If fails: identify breaking task(s), launch fix agent (sonnet), re-run until green
   - If passes: run code review gate from `references/code-review-gate.md` against files changed since last gate. If Critical, launch fix agent (sonnet), re-run until resolved.
   - If passes and CSS/layout touched: run design gate (if web-designer installed)
   - Reset counter, resume pool execution

4. **Natural drain gate**: If `active_slots == 0` AND queued tasks remain:
   - Run regression gate before launching the next batch

### Step 4: Final Integration Pass

After all tasks complete:

1. **Reconcile parallel conflicts**: duplicate files, naming drift, import conflicts.
2. **Cross-task integration**: verify dependent tasks integrate correctly.
3. **Add integration tests** if task-level coverage missed cross-task behavior.
4. **Run full regression** using the adapter's full test matrix.
5. Fix any failures. Re-run until green.

### Step 5: Completion Signal

Output the execution summary (see `references/execution-summary.md` for the rolling pool template) and announce:

"All N tasks complete. Final regression green. Proceeding to validation."

The `Stop` hook will detect this and chain into `/validate`.

## Error Handling

- **Test agent can't write meaningful tests**: Escalate to user.
- **Dev agent can't make tests pass after 2 attempts**: Escalate.
- **Regression gate fails**: Identify breaking task, fix it, re-run.
- **File conflict between parallel tasks**: Resolve in integration pass.
- **Pool stall**: If all active slots are occupied by stuck tasks, escalate rather than waiting.
- **Task subset not found**: List available task IDs from the plan.

## Example Usage

```
/super-swarm auth-plan.md
/super-swarm ./plans/phase-a-plan.md T1 T2 T4
```
