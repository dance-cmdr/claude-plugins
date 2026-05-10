---
name: skill-reviewer
description: Reviews SKILL.md files for quality and adherence to Anthropic best
  practices. Use when reviewing PRs that add or modify skill files, or when
  assessing skill quality during development.
---

# Skill Review Guide

Reviews Claude skills to ensure quality, clarity, and effectiveness against official Anthropic guidelines and internal standards.

## When This Skill Activates

- Reviewing new or modified skill files in PRs
- Quality assessment of existing skills
- Manual skill review during development (`/skill-reviewer`)

## When NOT to Activate

- Reviewing non-skill markdown files (README, docs, CLAUDE.md)
- General code review (use standard review process)
- Creating new skills (use as reference, not automation)

## Review Modes

This skill operates in two modes based on whether the skill is new or being edited.
The GHA workflow classifies each file in `changed-skill-files.txt`.

### New Skill (full review)

The file was added in this PR. Run the full review process below: all 6 steps, full
checklist, full best practices assessment. Use the complete output template.

### Modified Skill (diff-focused review)

The file already existed and was edited. This is the most common case.

**Do:**
- Read `skill-diff.txt` to understand what changed and why
- Read the full skill file for context (but don't review unchanged parts)
- Evaluate ONLY whether the changes maintain or improve quality
- Flag issues only if they are IN or CAUSED BY the diff
- Acknowledge what the change does well
- If the diff touches `.claude-plugin/marketplace.json` for this plugin, still
  perform Step 6 (Check Marketplace Tags) and block if tags are missing or
  undocumented

**Don't:**
- Re-review the entire skill against the full checklist
- Flag pre-existing issues that are unrelated to the change
- Suggest improvements to unchanged sections

**Diff-focused output:** Keep it minimal. Lead with what matters.

```markdown
## Skill Review: {skill-name} (edit)

*Change summary:* {1-2 sentences describing what was changed and why}

{If no issues: "Looks good — no issues found." and stop here.}

### Suggestions

1. *[Blocker/Major/Minor]* {suggestion tied to the diff}

{Include the Step 6 blocker block here if marketplace.json was touched and tags are missing/undocumented. Omit entirely if tags are present in both marketplace.json and the PR description.}
```

## Review Process (full review for new skills)

Copy and check off as you complete each step:

```markdown
Review Progress:

- [ ] Step 1: Fetch official best practices via WebFetch
- [ ] Step 2: Read the complete skill (all files in directory)
- [ ] Step 3: Evaluate against best practices
- [ ] Step 4: Check internal requirements
- [ ] Step 5: Validate frontmatter fields
- [ ] Step 6: Check marketplace tags (author-provided)
- [ ] Step 7: Post review using output format
```

### Step 1: Fetch Official Best Practices

Use WebFetch to retrieve the latest Anthropic skill authoring guidance:

- Primary: `https://code.claude.com/docs/en/skills`
- Supplementary: `https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills`

If fetches fail, proceed with `references/best-practices.md` and note that live docs could not be retrieved.

### Step 2: Read the Complete Skill

Read every file in the skill directory, not just SKILL.md. Check for:

- Supporting files (`references/`, `scripts/`, `assets/`, `examples/`)
- Templates and advanced docs (ADVANCED.md, TEMPLATES.md, etc.)
- Review the skill as a whole — supporting files are part of the skill

Determine review mode: check `changed-skill-files.txt` for whether each file is NEW or MODIFIED. For modified skills, also read `skill-diff.txt`.

### Step 3: Evaluate Against Best Practices

See `references/best-practices.md` for the 7 Anthropic principles plus verifiability.

### Step 4: Check Internal Requirements

See `references/checklist.md` for detailed criteria and anti-patterns.

### Step 5: Validate Frontmatter Fields

Every SKILL.md must have YAML frontmatter. Validate all fields present:

| Field                      | Required | Validation                                                   |
| -------------------------- | -------- | ------------------------------------------------------------ |
| `name`                     | Yes      | Lowercase, hyphens, numbers only. Max 64 chars               |
| `description`              | Yes      | Third-person, verb-led, includes triggers. Max 200 chars     |
| `disable-model-invocation` | No       | Boolean. Appropriate for side-effect skills (deploy, commit) |
| `user-invocable`           | No       | Boolean. Set `false` for background knowledge skills         |
| `allowed-tools`            | No       | Valid tool names. Check least-privilege principle             |
| `context`                  | No       | Only valid value is `fork`                                   |
| `agent`                    | No       | Valid agent type. Only when `context: fork` is set           |
| `argument-hint`            | No       | Short usage hint. Required when skill accepts user arguments |
| `model`                    | No       | Valid model identifier                                       |
| `hooks`                    | No       | Valid hook configuration                                     |

Flag: missing required fields, invalid values, `context: fork` without `agent`, `argument-hint` without argument placeholders in body.

### Step 6: Check Marketplace Tags

Tags power the filterable plugin catalog. The PR author — not the reviewer — is responsible for choosing them. Verify they exist and look sane, not generate them.

**When to run this check:**

- The plugin is new (being added to `.claude-plugin/marketplace.json` in this PR), OR
- The PR modifies the plugin's `marketplace.json` entry

Otherwise skip this step.

**What to verify:**

1. The plugin's entry in `marketplace.json` has a non-empty `tags` array with at least 3 tags.
2. Tags are lowercase, hyphen-separated, singular where practical.
3. The PR description explicitly lists the chosen tags.

**Do NOT propose, auto-generate, or suggest tags.** If tags are missing, insufficient, or not documented in the PR description, the author must add them. Block the merge — this is a **Blocker**.

**Output block** (append under Suggestions when the check fails):

```markdown
### Blocker: marketplace tags required

Pick 3-6 tags for this plugin and add them to two places:

1. The tags array in .claude-plugin/marketplace.json for this plugin
2. A ### Tags section in this PR's description, listing the same tags

Tags are human-chosen (not auto-suggested) so filtering in the plugin catalog
stays meaningful. Reuse existing tags from marketplace.json where possible.
```

If both places already have matching tags, no output — skip silently.

### Step 7: Post Review

Use the output format below. Post a single PR comment — do NOT split across multiple comments.

## Quick Review Checklist

Use this for a fast initial scan (30 seconds). For detailed criteria, proceed to reference materials.

| Criterion                  | What to Check                                                 |
| -------------------------- | ------------------------------------------------------------- |
| **Frontmatter**            | Has `name` (<=64 chars) and `description` (<=200 chars) in YAML |
| **Activation**             | Clear "When to Activate" and "When NOT to Activate" sections  |
| **Actionable**             | Provides concrete steps, not just concepts                    |
| **Scoped**                 | Focused on ONE domain/task, not everything                    |
| **Examples**               | Includes real code examples from the codebase                 |
| **Concise**                | Only adds context Claude doesn't already have                 |
| **Progressive disclosure** | Main file <500 lines, details in `references/`                |
| **Naming**                 | Name matches generality                                       |
| **Plugin scope**           | Skill is in the right plugin                                  |
| **No stale content**       | No hardcoded URLs, versions, or dates that will rot           |

## Output Format (new skills only)

The full template below is for **new skills only**. For modified skills, use the shorter diff-focused template from the Review Modes section above.

```markdown
## Skill Review: {skill-name}

{1-2 sentence overall assessment}

### Suggestions

1. *[Blocker/Major/Minor]* {Specific suggestion with explanation}
2. ...

{If no suggestions: "No issues found."}

{Include the Step 6 blocker block here only if tags are missing.}

<details>
<summary><strong>Detailed Assessment</strong></summary>

| Criterion | Status | Notes |
|-----------|--------|-------|
| Concise (no known-concept explanations) | pass/warn/fail | {brief note} |
| Third person description | pass/warn/fail | {brief note} |
| Appropriate degrees of freedom | pass/warn/fail | {brief note} |
| Progressive disclosure (<500 lines, refs/) | pass/warn/fail | {brief note} |
| Actionable workflows | pass/warn/fail | {brief note} |
| Single recommended pattern | pass/warn/fail | {brief note} |
| Description includes what + when | pass/warn/fail | {brief note} |
| Frontmatter (name + description) | pass/warn/fail | {brief note} |
| Activation boundaries (when / when not) | pass/warn/fail | {brief note} |
| Real codebase examples | pass/warn/fail | {brief note} |
| Appropriate scope (one domain) | pass/warn/fail | {brief note} |

</details>
```

## Reference Materials

- `references/best-practices.md` — Official Anthropic best practices (7 principles + verifiability)
- `references/checklist.md` — Detailed review criteria, anti-patterns, and severity levels
- `references/examples.md` — Good vs bad patterns with real skill examples

## Guidelines

- Be constructive, not pedantic — focus on issues that affect skill usability
- Review ALL changed files in the skill directory, not just SKILL.md
- If a skill is short and well-structured, keep the review brief
- Reference specific lines when suggesting changes
- If this skill-reviewer is in the changeset, still review it (self-review is fine)
- Do not suggest adding features or scope beyond what the skill intends to do

## Sources

- [Claude Code Skills Docs](https://code.claude.com/docs/en/skills)
- [Equipping Agents with Skills](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills)
- [Anthropic Skills Repo](https://github.com/anthropics/skills)

