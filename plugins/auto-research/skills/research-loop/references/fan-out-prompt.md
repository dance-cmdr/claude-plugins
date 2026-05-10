# Fan-out Prompt Template

This is the prompt template for each cluster agent launched during parallel fan-out.

## Cluster Agent Prompt

```
You are processing a cluster of findings through the Research-Review loop.

CLUSTER: {{cluster_id}} — {{theme}}
FINDINGS:
{{numbered findings list}}

NICHE CONTEXT: {{inferred from source — e.g., "GitHub PR review comments on a Python codebase"}}

Follow the loop protocol below. You are responsible for the full cycle:
Research → Review → Decide → (Spike/Pivot if needed) → up to 5 rounds.

When you need to PIVOT (round 3 with RED claims), launch a NEW Agent tool call
with clean context following the Pivot protocol.

Return your final consolidated result in the output format below.

---
{{inline contents of loop-protocol.md}}
---
{{inline Research and Review agent prompts from agent-prompts.md}}
---

FINAL OUTPUT FORMAT:

For each finding, report:
- FINDING: {{text}}
- VERDICT: AGREE | DISAGREE | UNCERTAIN
- NARRATIVE: {{1-3 sentences explaining the verdict with evidence}}
- EVIDENCE: {{file:line references}}
- ROUNDS_USED: {{N}}
- CLAIMS_VERIFIED: {{N}} GREEN, {{N}} AMBER, {{N}} RED

End with:
CLUSTER SUMMARY:
- Total findings: {{N}}
- Agreed: {{N}}
- Disagreed: {{N}}
- Uncertain: {{N}}
- Rounds used: {{max rounds across findings}}
```

## Construction Notes

When building this prompt at runtime:
1. Replace `{{cluster_id}}` and `{{theme}}` from the cluster metadata
2. Replace `{{numbered findings list}}` with the actual findings for this cluster
3. Inline the FULL contents of `loop-protocol.md` (not a reference — the agent needs the state machine in its context)
4. Inline the FULL contents of `agent-prompts.md` with niche-specific placeholders filled
5. The `NICHE CONTEXT` is inferred from the input source type or explicitly provided by the user
