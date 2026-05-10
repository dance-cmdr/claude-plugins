# Skill Review Checklist

Structured review criteria organized by severity. Use during Step 4 of the
review process.

## Critical (must fix before merge)

- [ ] SKILL.md exists with valid YAML frontmatter
- [ ] `name` field present, kebab-case (`[a-z0-9]+(-[a-z0-9]+)*`), max 64 chars
- [ ] `description` field present, non-empty
- [ ] Description uses third person, verb-led phrasing
- [ ] Description includes specific trigger phrases or activation conditions
- [ ] All files referenced in the skill body actually exist on disk
- [ ] No secrets, credentials, or API keys in skill content
- [ ] `disable-model-invocation: true` set for skills with destructive side effects

## Major (should fix before merge)

- [ ] SKILL.md body under 3,000 words
- [ ] Writing uses imperative/infinitive form, not second person ("you should")
- [ ] Progressive disclosure: detailed content in `references/`, not SKILL.md body
- [ ] Clear "When to Activate" section with concrete triggers
- [ ] Clear "When NOT to Activate" section with boundaries
- [ ] Description includes both WHAT the skill does and WHEN to use it
- [ ] `allowed-tools` restricts to minimum necessary (least privilege)
- [ ] No duplicated information across SKILL.md and supporting files
- [ ] Marketplace tags match plugin content (if applicable)
- [ ] `context: fork` is paired with `agent` field

## Minor (suggestions for improvement)

- [ ] SKILL.md body in 1,500-2,000 word sweet spot
- [ ] Description between 100-500 characters
- [ ] Keywords are relevant and non-redundant with the name
- [ ] Examples use real patterns, not toy examples
- [ ] Consistent terminology throughout skill and supporting files
- [ ] No stale content (hardcoded URLs, version numbers, dates)
- [ ] Supporting files have clear headings and scannable structure

## Anti-Patterns

### Vague description
The description doesn't give Claude enough signal to activate at the right time.

Bad: "Helps with code."
Good: "Reviews Python test files for adherence to pytest conventions. Activates
when the user asks to review tests, check test quality, or validate test
structure in `.py` files."

### Bloated SKILL.md
Everything crammed into one file. Claude loads all of it every time, even when
only a subset is relevant.

Fix: Extract reference material, checklists, and examples into `references/`.
Keep SKILL.md as the workflow driver that points to supporting files.

### Second-person instructions
"You should validate the frontmatter" reads as advice, not instruction. Claude
responds better to imperative form.

Fix: "Validate the frontmatter" — direct, unambiguous.

### Explaining known concepts
"JSON Schema is a vocabulary that allows you to annotate and validate JSON
documents." Claude already knows this. Token waste.

Fix: Remove. Only explain concepts specific to your domain or codebase.

### Auto-invoke with side effects
A skill that triggers automatically (no `disable-model-invocation`) AND performs
destructive actions (delete, deploy, commit). Risk of unintended execution.

Fix: Set `disable-model-invocation: true` for any skill with side effects.

### Orphaned references
SKILL.md mentions "See `references/advanced.md`" but the file doesn't exist.
Claude will try to read it, fail, and lose confidence in the skill.

Fix: Verify every referenced file exists. Remove stale references.

### Overly broad scope
One skill tries to handle code review, deployment, testing, and documentation.
Activation becomes unreliable because the description must cover too many triggers.

Fix: Split into focused skills, one domain each.
