# Grouping Strategies

## Purpose

Before fan-out, cluster findings into groups that share context. Each cluster gets one independent Research-Review loop. Good clustering reduces redundant exploration and catches cross-finding dependencies.

## Strategy: By File (default for code reviews)

Group findings that reference the same file path.

**When to use**: Code reviews, PR comments, lint findings — anything where file:line is the primary coordinate.

**Algorithm**:
1. Extract file paths from each finding
2. Group findings sharing the same file
3. If a file has 7+ findings, sub-group by function/class (use line ranges or grep for `def`/`class` boundaries)
4. If a finding references multiple files, place it in the cluster of its PRIMARY file (the one it's mainly about)

**Cluster limit**: Max 7 findings per cluster. Split if exceeded.

## Strategy: By Theme (default for spec/plan reviews)

Group findings that share a semantic category or concern.

**When to use**: Spec reviews, RFC feedback, plan critiques — where findings are about concepts rather than specific lines.

**Algorithm**:
1. Scan finding text for category indicators:
   - Explicit markers: [DESIGN], [PERF], [SECURITY], [NAMING], [ERROR], [TEST]
   - Keyword detection: "performance", "error handling", "naming", "security", "test", "scope", "dependency"
2. Group findings with overlapping categories
3. Findings with no clear category → "general" cluster (process last)

**Theme categories** (starter set, expand per niche):
- Architecture/Design
- Error handling/Resilience
- Performance/Scalability
- Security/Auth
- Naming/Conventions
- Testing/Coverage
- Scope/Boundaries
- Dependencies/Integration

## Strategy: By Severity (for triage)

Group findings by impact level, process critical first.

**When to use**: When time is limited and you need to address the most important findings first.

**Algorithm**:
1. Classify each finding: BLOCKER / MAJOR / MINOR / NIT
2. Group by severity level
3. Process in order: BLOCKER → MAJOR → MINOR → NIT
4. Stop if time/round budget exhausted (skip NITs)

**Severity signals**:
- BLOCKER: "must", "critical", "security vulnerability", "data loss", "breaks"
- MAJOR: "should", "important", "incorrect", "bug", "wrong"
- MINOR: "consider", "suggestion", "might", "could improve"
- NIT: "nit", "style", "preference", "optional"

## Strategy: By Dependency (for interconnected findings)

Group findings whose resolution depends on each other.

**When to use**: When findings reference shared state, or fixing one finding changes the context for another.

**Algorithm**:
1. Build a dependency graph:
   - Finding A references file X, Finding B modifies file X → dependent
   - Finding A says "change the return type", Finding B uses that return value → dependent
   - Finding A and B both reference the same function → potentially dependent
2. Find connected components in the graph
3. Each connected component = one cluster
4. Isolated findings (no dependencies) can be grouped by file or processed solo

## Choosing a Strategy

```
if input_source == "gh_pr_comments":
  primary = by_file
  fallback = by_theme (when files don't cluster well)

if input_source == "spec_review" or "plan_review":
  primary = by_theme
  fallback = by_severity (when themes are unclear)

if input_source == "triage" or user specifies urgency:
  primary = by_severity

if findings are highly interconnected (>50% share file references):
  primary = by_dependency
```

## Cluster Output Format

After grouping, each cluster should be structured as:

```
CLUSTER {{id}}:
  theme: {{theme or file_path}}
  strategy: {{which strategy was used}}
  finding_count: {{N}}
  files: [{{list of all file paths in this cluster}}]
  findings:
    - id: {{finding_id}}
      text: "{{finding text}}"
      file: {{file_path if applicable}}
      line: {{line number if applicable}}
      severity: {{if known}}
```
