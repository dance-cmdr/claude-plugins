# dance-cmdr/claude-plugins

Personal Claude Code plugin marketplace.

## Install

```bash
claude plugin marketplace add dance-cmdr/claude-plugins
```

## Plugins

### skill-reviewer

Reviews SKILL.md files against Anthropic best practices. Runs automatically via pre-push hook.

```bash
/skill-reviewer
```

### auto-research

Iterative Research-Review-Pivot verification loop for analyzing findings against a codebase.

```bash
/research-loop https://github.com/org/repo/pull/42
/generate gh-review
```

## Setup

Enable the pre-push skill review hook:

```bash
git config core.hooksPath .githooks
```
