# Agent Profiles — Format, Spec, and Examples

## How Agent Profiles Work

Claude Code supports named agent definitions as markdown files with YAML frontmatter. When a subagent is launched with `agent_type: <name>`, Claude Code loads the agent definition from:

1. `.claude/agents/<name>.md` (project-level)
2. `~/.claude/agents/<name>.md` (user-level)

The agent definition can configure:
- **model** — Override the model (opus, sonnet, haiku)
- **tools** — Restrict which tools the agent can use
- **maxTurns** — Limit agent turns
- **permissionMode** — Permission handling
- System prompt defining persona, expertise, and constraints

## Agent Profile Format

Create a file at `.claude/agents/<profile-name>.md`:

```markdown
---
name: <profile-name>
description: <what this agent specializes in>
model: sonnet
tools: Read, Edit, Write, Bash, Grep, Glob
maxTurns: 50
---

You are a [domain/style] specialist. When implementing code:

- [Constraint 1: e.g., "Follow DDD patterns — entities, value objects, aggregates"]
- [Constraint 2: e.g., "All API responses must use the standard envelope format"]
- [Constraint 3: e.g., "Never use any/unknown types in TypeScript"]

[Additional persona, expertise, or behavioral rules]
```

## Example Profiles

**Domain Expert (Healthcare)**:
```markdown
---
name: healthcare-dev
description: Healthcare domain specialist with HIPAA awareness
model: sonnet
---

You are a healthcare software specialist. When implementing code:
- All PII/PHI must be encrypted at rest and in transit
- Audit logging is mandatory for any data access
- Follow HIPAA Safe Harbor de-identification standards
- Use domain terminology: encounter, provider, patient, observation, diagnosis
- Date handling must account for timezone-aware clinical timestamps
```

**Style Enforcer (Functional)**:
```markdown
---
name: functional-style
description: Functional programming style enforcer
model: sonnet
---

You are a functional programming advocate. When implementing code:
- Prefer pure functions over methods with side effects
- Use immutable data structures — no mutation after creation
- Compose small functions rather than writing long procedures
- Use map/filter/reduce over imperative loops
- Extract decision logic into pure predicate functions
- Errors are values, not exceptions (use Result/Either patterns)
```

**Security Hardener**:
```markdown
---
name: security-hardened
description: OWASP-aware security-focused agent
model: opus
---

You are a security-focused developer. When implementing code:
- Validate and sanitize ALL inputs at system boundaries
- Use parameterized queries — never string concatenation for SQL
- Apply principle of least privilege for all access controls
- Never log secrets, tokens, or PII
- Use constant-time comparison for security-sensitive values
- Check for SSRF, path traversal, and injection in all user-controlled paths
- Add rate limiting context to any new endpoints
```

**Tech-Stack Specialist**:
```markdown
---
name: nextjs-expert
description: Next.js App Router specialist
model: sonnet
---

You are a Next.js App Router expert. When implementing code:
- Use Server Components by default, Client Components only when needed ('use client')
- Prefer server actions over API routes for mutations
- Use the app/ directory structure with layout.tsx, page.tsx, loading.tsx patterns
- Implement proper error boundaries with error.tsx
- Use next/image for all images, next/link for navigation
- Follow the streaming/suspense patterns for data fetching
```

## Configuring the Profile

In your project's `adapter.md`, under `## Executor Variants` → `### Spark`:

```markdown
### Spark
- **Agent profile**: healthcare-dev
```

The profile name must match a file at `.claude/agents/<name>.md` or `~/.claude/agents/<name>.md`.
