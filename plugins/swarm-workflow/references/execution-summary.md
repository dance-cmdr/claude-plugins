# Execution Summary Templates

Templates for the execution summary output by each swarm executor variant.

## Wave-Based (swarm, co-design)

```markdown
# Execution Summary

**Plan**: [filename]
**Date**: [date]
**Executor**: [swarm | co-design]

## Waves Executed: [M]

### Wave 1
| Task | Test Agent (RED) | Dev Agent (GREEN) | Status |
|------|-----------------|-------------------|--------|
| T1: [Name] | 5 tests, all RED | GREEN in 1 attempt | complete |
| T2: [Name] | 3 tests, all RED | GREEN in 2 attempts | complete |

**Regression gate**: [command] — PASSED

### Wave 2
| Task | Test Agent (RED) | Dev Agent (GREEN) | Status |
|------|-----------------|-------------------|--------|
| T3: [Name] | 4 tests, all RED | GREEN in 1 attempt | complete |

**Regression gate**: PASSED

## Integration Pass
- [Conflict or fix]: [Resolution]
- Tests added: [any integration tests]

## Final Regression
- Lint: PASSED
- Unit tests: PASSED (N tests)
- Integration tests: PASSED (N tests)
- E2E (if run): PASSED (N tests)

## Files Modified
[List of all changed files across all tasks]

## Issues Encountered
- [Task ID]: [Issue and resolution]

## Overall Status
All [N] tasks complete across [M] waves. Final regression green. Ready for /validate.
```

## Rolling Pool (super-swarm)

```markdown
# Execution Summary

**Plan**: [filename]
**Date**: [date]
**Executor**: super-swarm (rolling pool, max [N] concurrent)

## Task Completion Timeline

| Order | Task | Started | Completed | RED | GREEN | Regression Gate |
|-------|------|---------|-----------|-----|-------|-----------------|
| 1 | T1: [Name] | 0:00 | 0:05 | 5 tests | GREEN in 1 attempt | — |
| 2 | T2: [Name] | 0:00 | 0:07 | 3 tests | GREEN in 2 attempts | — |
| 3 | T3: [Name] | 0:01 | 0:08 | 4 tests | GREEN in 1 attempt | — |
| 4 | T4: [Name] | 0:05 | 0:12 | 2 tests | GREEN in 1 attempt | Gate @ task 4: PASSED |

## Regression Gates
| After Task # | Command | Result |
|-------------|---------|--------|
| 4 | [regression command] | PASSED |
| 8 | [regression command] | PASSED |
| Final | [full test matrix] | PASSED |

## Integration Pass
- [Conflict or fix]: [Resolution]
- Tests added: [any integration tests]

## Final Regression
- Lint: PASSED
- Unit tests: PASSED (N tests)
- Integration tests: PASSED (N tests)
- E2E (if run): PASSED (N tests)

## Files Modified
[List of all changed files across all tasks]

## Issues Encountered
- [Task ID]: [Issue and resolution]

## Overall Status
All [N] tasks complete. Final regression green. Ready for /validate.
```

## Tmux (swarm-tmux)

```markdown
# Execution Summary

**Plan**: [filename]
**Date**: [date]
**Executor**: swarm-tmux
**Session**: tmux attach -t [session-name]

## Waves Executed: [M]

### Wave 1
| Task | Pane (RED) | Pane (GREEN) | Status |
|------|-----------|-------------|--------|
| T1: [Name] | T1-red: 5 tests | T1-green: GREEN in 1 attempt | complete |
| T2: [Name] | T2-red: 3 tests | T2-green: GREEN in 2 attempts | complete |

**Regression gate**: [command] — PASSED

### Wave 2
| Task | Pane (RED) | Pane (GREEN) | Status |
|------|-----------|-------------|--------|
| T3: [Name] | T3-red: 4 tests | T3-green: GREEN in 1 attempt | complete |

**Regression gate**: PASSED

## Integration Pass
- [Conflict or fix]: [Resolution]
- Tests added: [any integration tests]

## Final Regression
- Lint: PASSED
- Unit tests: PASSED (N tests)
- Integration tests: PASSED (N tests)
- E2E (if run): PASSED (N tests)

## Files Modified
[List of all changed files across all tasks]

## Issues Encountered
- [Task ID]: [Issue and resolution]

## Overall Status
All [N] tasks complete across [M] waves. Final regression green. Ready for /validate.
```

## Spark (swarm-spark)

```markdown
# Execution Summary

**Plan**: [filename]
**Date**: [date]
**Executor**: swarm-spark
**Agent Profile**: [profile-name] ([profile-description])

## Waves Executed: [M]

### Wave 1
| Task | Test Agent (RED) | Dev Agent (GREEN) | Profile Applied | Status |
|------|-----------------|-------------------|-----------------|--------|
| T1: [Name] | 5 tests | GREEN in 1 attempt | Yes | complete |
| T2: [Name] | 3 tests | GREEN in 2 attempts | Yes | complete |

**Regression gate**: [command] — PASSED

## Profile Compliance
- All implementations follow [profile-name] constraints: [Yes/No]
- Notable profile-driven decisions: [list]

## Integration Pass
- [Conflict or fix]: [Resolution]
- Tests added: [any integration tests]

## Final Regression
- Lint: PASSED
- Unit tests: PASSED (N tests)
- Integration tests: PASSED (N tests)
- E2E (if run): PASSED (N tests)

## Files Modified
[List of all changed files across all tasks]

## Overall Status
All [N] tasks complete across [M] waves using [profile-name] profile. Final regression green. Ready for /validate.
```

## Co-Design (additional fields)

When using co-design executor, add these sections to the wave-based template:

```markdown
## Task Classification
| Task | Type | Reason |
|------|------|--------|
| T1: [Name] | standard | No design keywords |
| T2: [Name] | design | .css file + "layout" in description |

## Design Review Summary
- Wave 1: [N] findings ([critical/major/minor]), [resolution]
- Wave 2: No design tasks
```
