# Plan Template

Template for dependency-aware implementation plans produced by `/swarm-plan`.

```markdown
# Plan: [Task Name]

**Generated**: [Date]
**Features**: [feature references, if applicable]

## Overview
[Summary of task and approach]

## Dependency Graph

T1 --+-- T3 --+
     |        |-- T5 -- T6
T2 --+-- T4 --+

## Tasks

### T1: [Name]
- **depends_on**: []
- **files**: [exact source file paths]
- **test_type**: [unit | integration | e2e]
- **test_files**: [exact test file paths]
- **description**: [what to implement]
- **acceptance_criteria**:
  - [specific, testable criterion 1]
  - [specific, testable criterion 2]
- **validation**: [test command from adapter]
- **status**: pending
- **log**: []
- **files_modified**: []

### T2: [Name]
- **depends_on**: []
- **files**: [exact source file paths]
- **test_type**: [unit | integration | e2e]
- **test_files**: [exact test file paths]
- **description**: [what to implement]
- **acceptance_criteria**:
  - [specific, testable criterion 1]
- **validation**: [test command from adapter]
- **status**: pending
- **log**: []
- **files_modified**: []

### T3: [Name]
- **depends_on**: [T1]
- **files**: [exact source file paths]
- **test_type**: [unit | integration | e2e]
- **test_files**: [exact test file paths]
- **description**: [what to implement]
- **acceptance_criteria**:
  - [specific, testable criterion 1]
- **validation**: [test command from adapter]
- **status**: pending
- **log**: []
- **files_modified**: []

[... continue for all tasks ...]

## Parallel Execution Waves

| Wave | Tasks | Can Start When | Regression Gate |
|------|-------|----------------|-----------------|
| 1 | T1, T2 | Immediately | [regression gate from adapter] |
| 2 | T3, T4 | Wave 1 green | [regression gate from adapter] |
| 3 | T5 | T3, T4 green | Full regression + E2E |

## Testing Strategy
- **Test agent model**: opus (writes failing tests from acceptance criteria)
- **Dev agent model**: sonnet (implements to make tests pass)
- **Inter-wave regression**: [regression gate from adapter]
- **Final regression**: [full test matrix from adapter]

## Risks & Mitigations
- [What could go wrong + how to handle]
```
