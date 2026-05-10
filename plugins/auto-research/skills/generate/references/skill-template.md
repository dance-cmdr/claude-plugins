# Skill Template

This is the template used to generate niche-specific research skills. Placeholders use `{{double_braces}}` and are filled during generation.

## Generated SKILL.md Template

```yaml
---
name: {{skill_name}}
description: >
  {{skill_description}}
argument-hint: "{{argument_hint}}"
allowed-tools: Bash Read Grep {{extra_tools}}
---
```

```markdown
# {{skill_name}} — Iterative Verification

{{one_line_summary}}

## When to Use

- {{use_case_1}}
- {{use_case_2}}
- {{use_case_3}}

## Prerequisites

Read the reference files before starting:
1. `${CLAUDE_SKILL_DIR}/references/loop-protocol.md` — state machine and decide logic
2. `${CLAUDE_SKILL_DIR}/references/agent-prompts.md` — subagent prompt templates

## Phase 1: Ingest Findings

{{input_parsing_instructions}}

For each finding, extract:
\```
{ id, text, file_path (if referenced), line (if referenced), severity (inferred) }
\```

## Phase 2: Group into Clusters

Strategy: {{grouping_strategy}}

{{grouping_instructions}}

Report clusters to the user before proceeding.

## Phase 3: Fan-out

Launch one Agent tool call per cluster in a single message (parallel fan-out).

Each agent receives the cluster findings, loop protocol, and agent prompts.
Agents run the full Research-Review cycle independently.

## Phase 4: Consolidate

Merge results from all cluster agents.

## Phase 5: Output

{{output_format_instructions}}

## Edge Cases

- No findings: report "no actionable findings" and stop
- Single finding: skip grouping, run loop directly
- All GREEN in round 1: report immediately
- User interrupts: report current state and partial results
```

## Generated loop-protocol.md

Copy the contents of the source `loop-protocol.md` verbatim. This ensures the generated skill is standalone.

Source: `${CLAUDE_SKILL_DIR}/../../skills/research-loop/references/loop-protocol.md`

## Generated agent-prompts.md

Copy the agent prompt templates from the source, replacing the niche-specific placeholders with values from the chosen template:

- `{{niche_context}}` → from template's "Niche Context (for Research Agent)"
- Review context → from template's "Niche Context (for Review Agent)"  
- Pivot context → from template's "Niche Context (for Pivot Agent)"

Source: `${CLAUDE_SKILL_DIR}/../../skills/research-loop/references/agent-prompts.md`
Template: `${CLAUDE_SKILL_DIR}/../../templates/{{template_name}}.md`
