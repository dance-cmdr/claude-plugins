# skill-reviewer

Reviews SKILL.md files for quality and adherence to [Anthropic skill authoring best practices](https://code.claude.com/docs/en/skills).

## Install

```bash
claude plugin marketplace add anaconda/claude-plugins
claude plugin install skill-reviewer@anaconda-plugins
```

## Usage

Invoke manually to review a skill during development:

```
/skill-reviewer:skill-reviewer
```

The skill also runs automatically via the repository's [skill-review GitHub Actions workflow](../../.github/workflows/skill-review.yml), which posts a structured review comment on PRs that modify SKILL.md files.

### Cost & Usage Reporting

Each review comment includes a collapsible cost footer that accumulates across runs:

```
▶ Cost: $1.81 (3 runs) / $0.58 | Tokens: 6828 in / 9052 out | 166s
```

Click to expand a breakdown table showing totals and the last run's metrics:

| | Cost | Tokens in | Tokens out | Duration | Turns |
|---|---|---|---|---|---|
| **Total** | $1.81 | 20484 | 27156 | 498s | 84 |
| **This run** | $0.58 | 6828 | 9052 | 166s | 28 |

| Field | Meaning |
|-------|---------|
| **Cost** | AWS Bedrock spend (total across PR / this session) |
| **Tokens in** | Input tokens (non-cached only; cached context is ~90% cheaper) |
| **Tokens out** | Output tokens (tool calls, reasoning, review text) |
| **Duration** | Wall-clock time |
| **Turns** | Assistant responses (each tool call + response = 1 turn) |

## What It Reviews

- **Frontmatter validation**: `name` (kebab-case, max 64 chars), `description` (third-person, max 200 chars), optional fields
- **Content quality**: Writing style (imperative, not second-person), progressive disclosure, conciseness
- **Activation boundaries**: Clear "When to Activate" / "When NOT to Activate" sections
- **Marketplace tags**: Verifies tags exist and are documented in the PR description
- **Best practices**: Evaluated against the 7 Anthropic principles (see `references/best-practices.md`)

## Review Modes

**New skill** (added in a PR): Full review with detailed assessment table.

**Modified skill** (edited in a PR): Diff-focused review — only flags issues in or caused by the change.

## Contents

```
skills/skill-reviewer/
├── SKILL.md                        # Review process and output format
└── references/
    ├── best-practices.md           # 7 Anthropic principles + verifiability
    ├── checklist.md                # Criteria by severity (critical/major/minor)
    └── examples.md                 # Before/after patterns
```
