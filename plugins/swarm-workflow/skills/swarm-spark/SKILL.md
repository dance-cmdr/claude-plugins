---
name: swarm-spark
argument-hint: "<plan-file> [task-ids...]"
description: >
  Injects agent profiles into RED/GREEN subagents for domain expertise or style
  constraints via `.claude/agents/<name>.md`. Use with `/swarm-spark <plan-file>`.
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: prompt
          prompt: |
            You are checking whether a swarm-spark execution phase is complete.

            Examine this assistant message. Does it indicate that ALL planned tasks
            are finished, integrated, and the regression gate has passed? Look for:
            - "all tasks complete", "all N tasks implemented"
            - "final regression green", "regression gate passed"
            - "ready for validation", "run /validate"
            - An execution summary with no remaining or blocked tasks

            If swarm-spark execution IS complete, respond with:
            {"decision": "block", "reason": "Swarm-spark execution complete. Read the project adapter at .claude/adapter.md, then read and execute the validate skill at ${CLAUDE_PLUGIN_ROOT}/skills/validate/SKILL.md to run broad validation and phase closure."}

            If execution is NOT complete (partial progress, asking a question, debugging, waiting for user input, retrying tasks), respond with:
            {}

            The message to examine:
            $ARGUMENTS
          timeout: 15
---

# Swarm-Spark Executor — Agent Profile Injection

You are an Orchestrator. Parse plan files and execute tasks in parallel waves using **named agent profiles**. All subagents (both RED and GREEN) are launched with a user-defined `agent_type` that injects a custom persona, model configuration, and tool restrictions. This enables domain-specific, style-enforced, or security-hardened execution across the entire swarm.

## Prerequisites

- Read the project adapter at `.claude/adapter.md` for test commands, lint, conventions, regression gate commands, and the **Spark agent profile** configuration.
- If `.claude/adapter.md` does not exist, STOP with: "No adapter found. Copy the template from `references/adapter-template.md` and customize for your project."
- A plan file must exist (produced by `/swarm-plan`).
- An agent profile must be configured (see `references/profile-examples.md` for format and examples).

## Agent Profile System

Claude Code supports named agent definitions as markdown files with YAML frontmatter. When a subagent is launched with `agent_type: <name>`, Claude Code loads the agent definition from:

1. `.claude/agents/<name>.md` (project-level)
2. `~/.claude/agents/<name>.md` (user-level)

See `references/profile-examples.md` for the profile format and ready-to-use examples.

Configure the profile in your adapter under `## Executor Variants` → `### Spark`:
```markdown
### Spark
- **Agent profile**: <profile-name>
```

## Model Routing

| Agent Role | Model | Rationale |
|------------|-------|-----------|
| **Orchestrator** (you) | opus | Judgment calls, validation, conflict resolution |
| **Test Agent** (RED) | *from profile* (default: opus) | Profile may override for domain reasoning |
| **Dev Agent** (GREEN) | *from profile* (default: sonnet) | Profile may override for domain implementation |
| **Design Gate** (optional) | opus | Visual review of CSS/layout changes |

If the agent profile specifies a `model` in its frontmatter, that model overrides the defaults.

## Process

### Step 1: Load Agent Profile

1. Read adapter's `## Executor Variants` → `### Spark` → `Agent profile` value.
2. If no profile configured, STOP with error and configuration instructions.
3. Verify the agent definition file exists at `.claude/agents/<profile>.md` or `~/.claude/agents/<profile>.md`.
4. If not found, STOP with error listing both paths checked.
5. Read and log the profile name and description.

### Step 2: Parse Plan

Extract from user request:
1. **Plan file**: The markdown plan to read
2. **Task subset** (optional): Specific task IDs to run

Read and parse the plan:
1. Find task subsections, extract: Task ID, name, depends_on, files, test_files, test_type, description, acceptance_criteria, validation command
2. Build dependency graph and calculate waves

### Step 3: Execute Waves with Profile-Augmented Agents

For each wave, launch all unblocked tasks in parallel.

**For each task, execute two sequential agents with `agent_type: <profile>`:**

Use the spark-specific agent prompt variants from `references/swarm-agent-prompts.md` (the "Spark Agent Variants" section). These extend the standard RED/GREEN prompts with profile context.

1. **Phase A: Test Agent (RED)** — Launch with `agent_type: <profile>`. Validate RED evidence.
2. **Phase B: Dev Agent (GREEN)** — Launch with `agent_type: <profile>`. Validate GREEN evidence.

### Step 4: Inter-Wave Regression Gate

After ALL tasks in a wave complete:

1. Run regression gate command from adapter.
2. If fails: identify breaking task(s), launch fix agent with `agent_type: <profile>`, re-run until green.
3. **Code review gate**: Run the review from `references/code-review-gate.md` against all files changed in this wave. If Critical findings exist, launch a fix agent (sonnet) targeting the issues before proceeding.
4. If CSS/layout touched: run design gate (if web-designer installed).
5. Proceed to next wave.

### Step 5: Final Integration Pass

After all waves complete:

1. **Reconcile parallel conflicts**: duplicate files, naming drift, import conflicts.
2. **Cross-task integration**: verify dependent tasks integrate correctly.
3. **Profile compliance check**: review that implementations follow profile constraints.
4. **Run full regression** using the adapter's full test matrix.
5. Fix any failures. Re-run until green.

### Step 6: Completion Signal

Output execution summary (see `references/execution-summary.md` for spark template) and announce:

"All N tasks complete across M waves using [profile-name] profile. Final regression green. Proceeding to validation."

## Error Handling

- **No profile configured**: Stop with clear error and configuration instructions.
- **Profile file not found**: Stop with error listing paths checked.
- **Profile conflicts with project conventions**: Profile takes precedence for domain-specific decisions; project conventions for structural decisions.
- **Test/dev agent failures**: Same as base swarm — escalate after 2 attempts.
- **Regression gate fails**: Fix with profile-augmented agent, re-run.

## Example Usage

```
/swarm-spark auth-plan.md
/swarm-spark ./plans/api-redesign-plan.md T1 T3 T5
```
