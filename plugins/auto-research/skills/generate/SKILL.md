---
name: generate
description: >
  Generate a niche-specific research skill from templates. Creates a standalone
  skill with Research-Review-Pivot loop customized for your domain. Use when
  you want a permanent, reusable research skill for PR reviews, spec reviews,
  plan reviews, or a custom niche.
argument-hint: "[gh-review | spec-review | plan-review | custom]"
allowed-tools: Bash Read Write Edit
---

# generate — Research Skill Generator

Scaffold a standalone research skill customized for a specific domain.

## When to Use

- You want a permanent research skill for a specific review niche
- You want to customize the loop behavior for your workflow
- You want a skill that works independently (without auto-research installed)

## When NOT to Use

- You want to run a one-off research loop (use `/research-loop` directly)
- You want to understand how auto-research works (read the README)

## Built-in Templates

| Template | Best for |
|----------|----------|
| `gh-review` | GitHub PR review comments — groups by file, outputs PR comments |
| `spec-review` | Spec/RFC feedback — groups by theme, outputs markdown report |
| `plan-review` | Implementation plan feedback — groups by theme, outputs annotated plan |

## Process

### Step 1: Identify Template

If the user specified a template name in the argument, use it.

If not, or if "custom", ask:
"What kind of findings will you be researching? (PR review comments, spec feedback, plan critiques, or describe your niche)"

### Step 2: Interview (5 questions)

Ask these using AskUserQuestion, adapting based on the template chosen:

1. **Input source**: "Where do findings come from?"
   - GitHub PR comments (via `gh api`)
   - A markdown file with structured findings
   - Jira ticket comments
   - Pasted text in conversation
   - Custom (describe)

2. **Output target**: "Where should the generated skill live?"
   - New plugin directory (ask for path and name)
   - Existing plugin directory (ask which one)
   - Local `.claude/skills/` in a project (project-local, no plugin)
   - Current directory (for testing)

3. **Output format**: "How should results be delivered?"
   - PR comments (one per cluster)
   - Markdown report file
   - Annotated plan
   - Inline code suggestions
   - Custom (describe)
   
   Reference `${CLAUDE_SKILL_DIR}/references/output-formats.md` for details.

4. **Exploration scope**: "What should the Research agent explore?"
   - Changed files + imports + tests (typical for code reviews)
   - Full codebase + docs (typical for spec reviews)
   - Referenced files + git history (typical for plan reviews)
   - Custom (describe)

5. **Skill name**: "What should the skill be called?"
   - Suggest a default based on template (e.g., `pr-research`, `spec-research`)
   - Must be kebab-case

### Step 3: Read Source Materials

Read these files to assemble the generated skill:

1. Template: `${CLAUDE_SKILL_DIR}/../../templates/{{template_name}}.md`
2. Loop protocol: `${CLAUDE_SKILL_DIR}/../research-loop/references/loop-protocol.md`
3. Agent prompts: `${CLAUDE_SKILL_DIR}/../research-loop/references/agent-prompts.md`
4. Skill template: `${CLAUDE_SKILL_DIR}/references/skill-template.md`

### Step 4: Generate Files

Create the output structure:

```
{{output_target}}/
├── .claude-plugin/
│   └── plugin.json           # Only if output target is a plugin
└── skills/
    └── {{skill_name}}/
        ├── SKILL.md           # Orchestration skill (~250 lines)
        └── references/
            ├── loop-protocol.md    # Full state machine (copied from source)
            └── agent-prompts.md    # Niche-customized prompts
```

**SKILL.md**: Use `skill-template.md` as the structure. Fill placeholders with:
- Niche context from the chosen template
- Input parsing instructions from the template
- Grouping strategy from the template
- Output format instructions from interview answer

**loop-protocol.md**: Copy verbatim from the research-loop source. Do not modify.

**agent-prompts.md**: Copy the agent prompt templates, replacing `{{niche_context}}` placeholders with the niche-specific context from the chosen template.

**plugin.json** (if applicable):
```json
{
  "name": "{{plugin_name}}",
  "version": "0.1.0",
  "description": "{{niche}} research skill — iterative verification loop"
}
```

### Step 5: Verify

After writing all files:
1. Read back the generated SKILL.md and confirm it references the correct relative paths
2. Verify `loop-protocol.md` was copied completely
3. Verify `agent-prompts.md` has niche context filled in (no remaining `{{placeholders}}`)
4. Report to user: "Generated skill at `{{path}}`. Test with: `claude --plugin-dir {{path}}`"

## Customization Guidance

If the user chose "custom" for any interview question, help them define:
- **Custom input parsing**: What format are their findings in? How to extract structured records?
- **Custom grouping**: What dimension should findings be clustered on?
- **Custom output**: What sections, metadata, and delivery method do they need?
- **Custom scope**: What parts of their codebase are relevant?

Write their custom definitions directly into the generated skill (no placeholder references to templates that won't exist in the standalone skill).
