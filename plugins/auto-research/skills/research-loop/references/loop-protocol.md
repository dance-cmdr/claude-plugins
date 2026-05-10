# Loop Protocol — State Machine

## States

```
INIT → RESEARCH → REVIEW → DECIDE → [SPIKE | NEXT_ROUND | PIVOT | DONE]
```

## Loop State Tracking

Track state as structured text in the conversation. Update after each phase:

```
LOOP STATE:
  cluster_id: <id>
  round: <1-5>
  scope: narrow | medium | wide
  claims:
    - id: 1
      text: "..."
      status: GREEN | AMBER | RED
      evidence: "file:line or grep output"
      spike_attempted: true | false
    - id: 2
      ...
  history:
    - round: 1
      approach: "checked error handling in handler.py"
      outcome: "2 GREEN, 1 AMBER, 1 RED"
    - round: 2
      ...
```

## Decide Logic

After each Review phase, evaluate:

```
if all claims GREEN:
  → DONE (success)

if any claim AMBER and spike not yet attempted for that claim:
  → SPIKE (focused deep-dive on AMBER claims only)
  → then re-evaluate

if any claim RED and round < 3:
  → NEXT_ROUND
  → Research receives Review feedback, refines RED claims
  → scope escalates: round 1 = narrow, round 2+ = medium

if any claim RED and round == 3:
  → PIVOT
  → Fresh agent with clean context
  → scope = wide

if any claim RED and round > 3:
  → NEXT_ROUND (give Pivot more attempts)

if round == 5:
  → DONE (partial)
  → Report unresolved claims in final output
```

## Scope Escalation

| Round | Scope | What to explore |
|-------|-------|-----------------|
| 1 | narrow | Only files referenced in findings |
| 2 | medium | Referenced files + direct callers + tests + imports |
| 3 (pre-pivot) | medium | Same as round 2 with Review feedback |
| Pivot (3+) | wide | Full codebase search, git history, adjacent systems, config |
| 4-5 (post-pivot) | wide | Pivot continues with wide scope |

## AMBER Spike Protocol

When a claim is rated AMBER:

1. Isolate the specific claim and its evidence path
2. Conduct a focused investigation (narrow scope, deep dive):
   - Read the referenced file in full (not just the line)
   - Check git log for recent changes to that area
   - Search for related patterns (same function name, similar logic)
   - Look for documentation or comments explaining intent
3. Rate the result:
   - If evidence found → upgrade to GREEN
   - If evidence contradicts → downgrade to RED
   - If still inconclusive → stays AMBER (escalate in final report)

One spike attempt per claim per round. Do not spike the same claim twice.

## Pivot Trigger Protocol

When Decide triggers PIVOT at round 3:

1. Summarize what was tried and disproven:
   ```
   DISPROVEN APPROACHES:
   - Approach: "checked validation in handler.py line 45"
     Result: "function doesn't exist, was removed in commit abc123"
   - Approach: "looked for error propagation in middleware"
     Result: "middleware doesn't handle this error type"
   ```

2. Construct Pivot agent prompt with ONLY:
   - Original findings (raw text, no annotations)
   - File paths referenced in findings
   - The disproven summary above
   - Instruction: "Take a DIFFERENT angle. Do NOT repeat these approaches."

3. Launch as new Agent tool call (fresh context, no anchoring)

4. Pivot agent has 2 remaining rounds (4 and 5) to resolve

## Structural Impossibility

When Review proves something structurally doesn't exist (referenced function, API, file, pattern):

1. Review flags it explicitly:
   ```
   STRUCTURAL IMPOSSIBILITY: {what doesn't exist}
   EVIDENCE: {grep output showing absence, git log showing removal}
   ```

2. This goes into the disproven summary for Pivot

3. Pivot's job shifts: instead of verifying the original claim, produce a **counter-proposal**:
   - What DOES exist in its place?
   - What was the reviewer likely thinking of?
   - What should the response to the reviewer be?

## Round Transitions

### RESEARCH → REVIEW
Pass: all claims with evidence paths

### REVIEW → DECIDE
Pass: all claims with ratings + evidence

### DECIDE → NEXT_ROUND
Pass to Research: Review feedback per RED/AMBER claim, updated scope level

### DECIDE → PIVOT
Pass to Pivot agent: raw findings, file paths, disproven summary (see Pivot Trigger Protocol)

### DECIDE → DONE
Pass to Consolidate: all claims with final ratings, evidence trails, full history
