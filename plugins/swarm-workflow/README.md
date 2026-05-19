# swarm-workflow

A parallel TDD development pipeline for Claude Code. Takes a feature from idea to shipped code through four phases: specification, planning, swarm execution with RED/GREEN agent separation, and validation.

## Install

```bash
claude plugin marketplace add dance-cmdr/claude-plugins
claude plugin install swarm-workflow@dance-cmdr-plugins
```

## Prerequisites

Each project that uses this plugin needs a `.claude/adapter.md` file describing the project's stack, test commands, file patterns, and conventions. The adapter is the single source of truth that all skills read before doing anything.

Copy the template to your project and customize it:

```bash
cp "$(claude --print-plugin-dir swarm-workflow)/references/adapter-template.md" .claude/adapter.md
```

See `references/examples/pythonanywhere-adapter.md` for a real-world example.

## The Pipeline

```
/spec → /swarm-plan → /swarm → /validate
```

### 1. `/swarm-workflow:spec` — Specification Discovery

Interactive discovery that transforms an idea into a structured spec with acceptance criteria.

```bash
/swarm-workflow:spec "Add user authentication"
```

Produces a spec at `docs/specs/YYYY-MM-DD-<name>.md` with problem statement, requirements, acceptance criteria, and test plan.

### 2. `/swarm-workflow:swarm-plan` — Dependency-Aware Planning

Decomposes a spec into atomic tasks optimized for parallel execution.

```bash
/swarm-workflow:swarm-plan docs/specs/2026-05-03-auth.md
```

Each task has explicit dependencies, file ownership (no two tasks edit the same file), and a test strategy. Tasks are grouped into waves based on the dependency DAG.

### 3. `/swarm-workflow:swarm` — Parallel TDD Executor

Executes the plan using separated test and dev agents.

```bash
/swarm-workflow:swarm auth-plan.md
```

**The RED/GREEN pattern:**

For each task in a wave:
1. **Test Agent (RED)** writes failing tests encoding the acceptance criteria. Verifies they fail for the right reason.
2. **Dev Agent (GREEN)** implements minimal code to make all tests pass. Does not modify test files.
3. **Regression gate** runs between waves (tests + code review via five-axis gate). No wave launches until the gate is green.

After all waves complete, an integration pass resolves cross-task conflicts, then auto-chains to `/validate`.

### 4. `/swarm-workflow:validate` — Validation & Phase Closure

Full quality pass: test matrix, regression check, cleanup, code review, security audit, documentation updates.

```bash
/swarm-workflow:validate
```

Checks for debug statements, commented-out code, TODO items, and verifies all acceptance criteria are met. Produces a phase closure document.

## Executor Variants

The base `/swarm` runs waves sequentially. Four variants offer different execution models:

| Command | What it does | When to use |
|---------|-------------|-------------|
| `/swarm-workflow:super-swarm` | Rolling pool of up to 12 concurrent RED/GREEN pairs | Large plans with many independent tasks |
| `/swarm-workflow:swarm-tmux` | Each agent runs in a visible tmux pane | Debugging, watching agents work in real-time |
| `/swarm-workflow:co-design` | Routes design tasks differently from standard tasks | Frontend work with design system constraints |
| `/swarm-workflow:swarm-spark` | Injects named agent profiles into all subagents | Domain expertise (healthcare, functional style, etc.) |

All variants share the same plan format, adapter, and regression gate logic. They also share identical Stop hook logic (detects completion and chains to `/validate`). The Stop hook prompt is duplicated in each skill's frontmatter because Claude Code's skill hook schema requires inline `prompt:` values — there is no `file:` indirection for prompt-type hooks. When updating the hook prompt in one variant's frontmatter, update all five (swarm, co-design, super-swarm, swarm-spark, swarm-tmux).

All executor skills require explicit `/` invocation (`disable-model-invocation: true`). This is intentional — executors launch multiple subagents and run test suites, which is expensive in both tokens and time. Preventing auto-invocation ensures users consciously choose when to start execution rather than having Claude trigger it from conversation context.

## Design Review

```bash
/swarm-workflow:design-review
```

Read-only design reviewer using Playwright MCP. Screenshots the running app and evaluates against the project's design system. Never edits code — review only. Automatically invoked by `/co-design` after waves that touch CSS/layout.

## Hooks

### Auto-lint

Runs your linter after every Write/Edit operation. Configure the linter commands in `hooks/auto-lint.sh` for your project's stack. Ships as a template — uncomment and set up your linter commands.

### Tmux Worker

Helper script for `/swarm-tmux`. Manages tmux sessions, spawns `claude -p` agents in panes, and tracks completion via log files.

## Model Routing

The skills recommend specific models for different agent roles:

| Role | Recommended | Why |
|------|------------|-----|
| Orchestrator | Opus | Judgment, conflict resolution |
| Test Agent (RED) | Opus | Edge cases, acceptance criteria depth |
| Dev Agent (GREEN) | Sonnet | Fast implementation, tests define the contract |
| Validator | Opus | Broad analysis |

These are recommendations. Claude Code uses your configured model by default — the skills work with any model.

## Adapter Reference

The adapter (`.claude/adapter.md`) tells the skills about your project. Key sections:

| Section | What to configure |
|---------|-------------------|
| Stack | Languages, frameworks, tools |
| Test Matrix | Test types, runners, when to use each |
| Regression Gate | Command that runs between swarm waves |
| Lint | Your lint command |
| Conventions | Spec paths, feature tracker, design docs |
| File Patterns | Where components, tests, styles live |

See `references/adapter-template.md` for the full template.

## Contents

```
plugins/swarm-workflow/
├── skills/           # 9 workflow skills
├── commands/         # 9 slash command wrappers
├── hooks/            # Auto-lint + tmux worker
├── references/
│   ├── adapter-template.md
│   └── examples/
│       └── pythonanywhere-adapter.md
└── README.md
```
