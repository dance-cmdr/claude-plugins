# dance-cmdr/claude-plugins

Personal Claude Code plugin marketplace.

## Install

```bash
claude plugin marketplace add dance-cmdr/claude-plugins
```

## Plugins

| Plugin | Description | Commands |
|--------|-------------|----------|
| [skill-reviewer](plugins/skill-reviewer/) | Reviews SKILL.md files against Anthropic best practices | `/skill-reviewer` |
| [auto-research](plugins/auto-research/) | Iterative Research-Review-Pivot verification loop with skill generator | `/research-loop`, `/generate` |
| [swarm-workflow](plugins/swarm-workflow/) | Parallel TDD development pipeline: spec, plan, swarm execution with RED/GREEN agent separation, and validation | `/spec`, `/swarm-plan`, `/swarm`, `/validate`, `/co-design`, `/swarm-spark`, `/swarm-tmux`, `/super-swarm` |

## Setup

Enable the pre-push skill review hook:

```bash
git config core.hooksPath .githooks
```
