# CLAUDE.md

Personal Claude Code plugin marketplace. Install via:

```
claude plugin marketplace add dance-cmdr/claude-plugins
```

## Directory Layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace catalog
├── .githooks/
│   └── pre-push               # Git hook: skill-review on push
├── .claude/
│   └── hooks/
│       └── pre-push-skill-review.sh  # Skill review logic
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── <skill-name>/
│               └── SKILL.md
├── CLAUDE.md
└── README.md
```

## Schema Rules

Same as anaconda/claude-plugins — see marketplace.json and plugin.json schemas.

### marketplace.json

Allowed fields at root: `$schema`, `name`, `version`, `description`, `owner`, `metadata`, `plugins`.

Each `plugins[]` entry allows: `name`, `source`, `description`, `version`, `author`, `tags`, `keywords`.

### plugin.json

`name` is the only required field. Must match directory name, kebab-case.

## Pre-push Skill Review

This repo uses a git pre-push hook instead of CI for skill review.

### Setup

```bash
git config core.hooksPath .githooks
```

### Behavior

On every push, the hook:
1. Detects new/modified SKILL.md files compared to the remote branch
2. Classifies them as `new` (full review) or `modified` (diff-focused review)
3. Runs Claude with the skill-reviewer plugin
4. Blocks the push if Critical issues are found

### Skipping (when needed)

```bash
git push --no-verify
```

## Conventions

- Plugin names: kebab-case, lowercase, descriptive
- SKILL.md: YAML frontmatter with `name` and `description`
- All `source` paths in marketplace.json start with `./plugins/`
