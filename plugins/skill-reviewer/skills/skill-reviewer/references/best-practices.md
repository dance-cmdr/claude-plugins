# Anthropic Skill Authoring Best Practices

Seven principles for writing effective Claude Code skills, synthesized from
official Anthropic documentation and engineering guidance.

## 1. Progressive Disclosure

Load information in layers, not all at once.

- **Level 1 — Metadata**: `name` and `description` in frontmatter. Claude reads
  these for every skill on every turn to decide whether to activate. Keep them
  tight and trigger-rich.
- **Level 2 — SKILL.md body**: The main instructions. Loaded when Claude decides
  to activate. Target 1,500-2,000 words; never exceed 3,000.
- **Level 3 — Supporting files**: `references/`, `examples/`, `scripts/`. Loaded
  only when the skill body tells Claude to read them.

If the SKILL.md body tries to contain everything, it wastes tokens on turns where
the skill activates but only needs a subset of the content.

## 2. Simplicity and Clarity

Skills are markdown with YAML frontmatter. No special syntax, no DSL.

- Write in imperative/infinitive form ("Validate the frontmatter", not "You should
  validate the frontmatter")
- One idea per paragraph
- Use tables for structured data, not prose
- Avoid jargon Claude already knows — don't explain what JSON Schema is or how
  YAML frontmatter works

## 3. Evaluation-Driven Development

Start from a capability gap, not from "what could we skill-ify?"

- Identify a task where Claude's default behavior is wrong or incomplete
- Write the skill to close that specific gap
- Test with real prompts and verify Claude activates at the right time
- Iterate on the description triggers until activation is reliable

## 4. Structure for Scale

Split content across files so skills stay maintainable.

- `SKILL.md` — Core instructions and workflow
- `references/` — Detailed reference material, checklists, standards
- `examples/` — Before/after patterns, sample outputs
- `scripts/` — Executable helpers

Reference supporting files explicitly: "See `references/checklist.md` for
detailed criteria." Claude will read them when needed.

## 5. Metadata-First Design

`name` and `description` are the most important fields. Claude uses them to
decide whether to activate the skill on every single turn.

**Name**: Lowercase, hyphens, numbers. Max 64 characters. The name becomes the
skill's namespace (`/plugin-name:skill-name`), so it should be descriptive
enough to recognize at a glance.

**Description**: Third-person, verb-led. Must include:
- WHAT the skill does
- WHEN to activate (trigger phrases, file patterns, situations)

Good: "Reviews SKILL.md files for quality and adherence to Anthropic best
practices. Use when reviewing PRs that add or modify skill files."

Bad: "A skill for reviewing things."

Combined `description` + `when_to_use` must stay under 1,536 characters.

## 6. Iterate with Claude

Skills are collaborative artifacts. Use Claude to help refine them.

- Ask Claude to attempt the task without the skill, note where it fails
- Write the skill to address those failures
- Test with Claude, observe where it still goes wrong
- Update the skill based on real activation behavior
- Pay attention to false activations (triggers too broadly) and missed
  activations (description doesn't match the user's phrasing)

## 7. Security-First

Skills run with Claude's full tool access by default.

- Use `allowed-tools` in frontmatter to restrict tool access to the minimum needed
- Use `disable-model-invocation: true` for skills with side effects (deploy,
  commit, delete) so they only run when the user explicitly invokes them
- Audit any scripts in `bin/` or `scripts/` — they run with the user's permissions
- Never include secrets or credentials in skill content

## Verifiability

Beyond the seven principles, every skill should be testable:

- Can you trigger the skill with a known prompt?
- Does it produce the expected output?
- Does it NOT trigger on prompts where it shouldn't?
- Are the supporting files it references actually read when needed?

Test activation by running `claude --plugin-dir ./plugins/<name>` and trying
representative prompts. Check Claude's tool use to verify which files were read.
