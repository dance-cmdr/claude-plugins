# auto-research

Iterative Research-Review-Pivot verification loop for analyzing findings against a codebase. Adapts to any review niche via a skill generator.

## Install

```bash
claude plugin marketplace add anaconda/claude-plugins
claude plugin enable auto-research
```

## Skills

### `/research-loop`

Run the verification loop directly on any set of findings.

```
/research-loop https://github.com/org/repo/pull/42
/research-loop path/to/review-comments.md
/research-loop paste
```

`paste` — enter findings as a markdown list in the next prompt (one bullet per finding).

Processes findings through multi-round Research→Review cycling:
- **Research agent** explores codebase, produces claims with evidence paths
- **Review agent** verifies claims using 5 Whys depth, rates RED/AMBER/GREEN
- **Pivot agent** (round 3+) takes fresh approach with clean context if claims stay RED

### `/generate`

Scaffold a standalone niche-specific research skill from built-in templates.

```
/generate gh-review
/generate spec-review
/generate plan-review
/generate custom
```

Generated skills are completely standalone — they work without auto-research installed.

## Built-in Templates

| Template | Input | Grouping | Output |
|----------|-------|----------|--------|
| `gh-review` | GitHub PR comments via `gh api` | By file | PR reply comments |
| `spec-review` | Markdown review file | By theme | Markdown report |
| `plan-review` | Markdown review file | By theme | Annotated plan assessment |

## How It Works

```
Input → Group → Fan-out → [Research → Review → Decide] × 5 rounds max → Output
```

Claim states:
- **GREEN** — verified true, act on it
- **AMBER** — partially true, spiked within loop for deeper evidence
- **RED** — disproven, triggers next round or Pivot

Scope escalates adaptively: narrow (round 1) → medium (round 2+) → wide (Pivot).

## Architecture

```
plugins/auto-research/
├── skills/
│   ├── research-loop/          # Core loop skill
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── loop-protocol.md
│   │       ├── agent-prompts.md
│   │       └── grouping-strategies.md
│   └── generate/               # Skill generator
│       ├── SKILL.md
│       └── references/
│           ├── skill-template.md
│           └── output-formats.md
└── templates/                  # Niche templates
    ├── gh-review.md
    ├── spec-review.md
    └── plan-review.md
```

No `agents/` directory — subagents are constructed dynamically at runtime from prompt templates in `references/agent-prompts.md`. No `bin/` — all logic is orchestrated by Claude via the skill instructions.
