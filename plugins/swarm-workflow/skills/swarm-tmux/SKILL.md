---
name: swarm-tmux
argument-hint: "<plan-file> [task-ids...]"
description: >
  Wave-based parallel executor with live tmux visibility — each agent runs as
  `claude -p` in its own pane. Watch agents work in real-time. Requires tmux.
  Use with `/swarm-tmux <plan-file>`.
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            You are checking whether a swarm-tmux execution phase is complete.

            Examine this assistant message. Does it indicate that ALL planned tasks
            are finished, integrated, and the regression gate has passed? Look for:
            - "all tasks complete", "all N tasks implemented"
            - "final regression green", "regression gate passed"
            - "ready for validation", "run /validate"
            - An execution summary with no remaining or blocked tasks

            If swarm-tmux execution IS complete, respond with:
            {"decision": "block", "reason": "Swarm-tmux execution complete. Read the project adapter at .claude/adapter.md, then read and execute the validate skill at ${CLAUDE_PLUGIN_ROOT}/skills/validate/SKILL.md to run broad validation and phase closure."}

            If execution is NOT complete (partial progress, asking a question, debugging, waiting for user input, retrying tasks), respond with:
            {}

            The message to examine:
            $ARGUMENTS
          timeout: 15
---

# Swarm-Tmux Executor — Wave-Based TDD with Live Tmux Visibility

You are an Orchestrator. Parse plan files and execute tasks in parallel waves where **each agent runs as `claude -p` in a live tmux pane**. Users can attach to the tmux session and watch agents work in real time. For each task: a test agent writes failing tests (RED), then a dev agent implements until green (GREEN). Between waves, run regression gates.

## Prerequisites

- Read the project adapter at `.claude/adapter.md` for test commands, lint, conventions, and regression gate commands.
- If `.claude/adapter.md` does not exist, STOP with: "No adapter found. Copy the template from `references/adapter-template.md` and customize for your project."
- A plan file must exist (produced by `/swarm-plan`).
- **tmux must be installed**. Run `which tmux` to verify. If not found, tell the user to install it and stop.

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

### Step 2: Initialize Tmux Session

Use the helper script at `${CLAUDE_PLUGIN_ROOT}/hooks/tmux_spawn_worker.sh`:

```bash
"${CLAUDE_PLUGIN_ROOT}/hooks/tmux_spawn_worker.sh" init "swarm-$(basename "$PLAN_FILE" .md)"
```

Tell the user how to attach: `tmux attach -t swarm-<plan-name>`

### Step 3: Execute Waves with Tmux Panes

For each wave, launch all unblocked tasks in parallel.

**For each task, run two sequential agents in tmux panes using prompts from `references/swarm-agent-prompts.md`:**

#### Phase A: Test Agent (RED)

1. Write the RED agent prompt (from reference, with task context injected) to a temp file
2. Spawn in a tmux pane:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/hooks/tmux_spawn_worker.sh" spawn "$SESSION" "T1-red" "$PROMPT_FILE" "--model opus"
   ```
3. Monitor until the pane's process exits:
   ```bash
   while "${CLAUDE_PLUGIN_ROOT}/hooks/tmux_spawn_worker.sh" status "$SESSION" "T1-red"; do
     sleep 5
   done
   ```
4. Read output log and validate RED evidence

#### Phase B: Dev Agent (GREEN)

1. Write the GREEN agent prompt (from reference, with task context injected) to a temp file
2. Spawn:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/hooks/tmux_spawn_worker.sh" spawn "$SESSION" "T1-green" "$PROMPT_FILE" "--model sonnet"
   ```
3. Monitor until complete. Validate GREEN evidence.

**Launch all tasks in a wave in parallel** — each task's RED/GREEN sequence runs independently.

### Step 4: Inter-Wave Regression Gate

After ALL tasks in a wave complete:

1. Run regression gate command from adapter.
2. If fails: identify breaking task(s), launch fix agent in a new pane, re-run until green.
3. **Code review gate**: Run the review from `references/code-review-gate.md` against all files changed in this wave. If Critical findings exist, launch a fix agent (sonnet) targeting the issues before proceeding.
4. If CSS/layout touched: run design gate (if web-designer installed).
5. Proceed to next wave.

**Do NOT launch the next wave until regression is green.**

### Step 5: Final Integration Pass

After all waves complete:

1. **Reconcile parallel conflicts**: duplicate files, naming drift, import conflicts.
2. **Cross-task integration**: verify dependent tasks integrate correctly.
3. **Add integration tests** if task-level coverage missed cross-task behavior.
4. **Run full regression** using the adapter's full test matrix.
5. Fix any failures. Re-run until green.

### Step 6: Cleanup & Completion Signal

1. Clean up temp prompt files: `rm -f /tmp/swarm-red-* /tmp/swarm-green-*`
2. Optionally kill session: `"${CLAUDE_PLUGIN_ROOT}/hooks/tmux_spawn_worker.sh" cleanup "$SESSION"`
3. Output execution summary (see `references/execution-summary.md` for tmux template) and announce:

"All N tasks complete across M waves. Final regression green. Proceeding to validation."

## Error Handling

- **tmux not installed**: Stop immediately with install instructions.
- **Test agent can't write meaningful tests**: Escalate to user.
- **Dev agent can't make tests pass after 2 attempts**: Escalate.
- **Regression gate fails**: Identify breaking task, fix in new pane, re-run.
- **Pane exits with error**: Check output log, diagnose, retry or escalate.

## Example Usage

```
/swarm-tmux auth-plan.md
/swarm-tmux ./plans/phase-a-plan.md T1 T2 T4
```
