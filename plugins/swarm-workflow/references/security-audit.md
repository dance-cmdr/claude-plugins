# Security Audit

Run this audit during the validate phase (Step 5).
Evaluates all changed files for exploitable vulnerabilities.

---

## Audit Dimensions

### 1. Input Handling
- Boundary controls on user-provided values (length, type, range)
- Injection vectors: SQL, command, template, XSS, path traversal
- Output encoding (HTML entities, URL encoding where displayed)
- File upload restrictions (type, size, content validation)

### 2. Authentication & Authorization
- Password hashing uses current standards (bcrypt, argon2 — not MD5/SHA1)
- Session management (expiry, rotation, secure flags)
- Every endpoint has appropriate auth checks
- IDOR risks (direct object references without ownership verification)
- Rate limiting on sensitive operations (login, password reset, API keys)

### 3. Data Protection
- Secrets never appear in code, logs, or error messages
- Sensitive fields excluded from API responses and serialization
- Encryption in transit (TLS) and at rest where required
- PII handling follows applicable compliance requirements

### 4. Infrastructure
- Security headers present (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- CORS configured with specific origins (not wildcard in production)
- Dependencies checked for known CVEs
- Error messages don't leak internal details to users
- Principle of least privilege applied to service accounts and roles

### 5. Third-Party Integrations
- API keys stored in environment/secrets, not code
- Webhook endpoints verify signatures
- OAuth implementations use state parameter and PKCE where applicable
- External data treated as untrusted (validated before use)

## Severity Classification

| Severity | Gate impact | Criteria |
|----------|-----------|----------|
| **Critical** | Blocks validation | Exploitable vulnerability with clear attack vector |
| **High** | Blocks validation | Vulnerability requiring specific conditions to exploit |
| **Medium** | Flagged, doesn't block | Defense-in-depth gap, no immediate exploit path |
| **Low** | Informational | Best practice deviation, theoretical risk |

## Output

```markdown
## Security Audit

### Findings

| # | Severity | File | Description | Recommendation |
|---|----------|------|-------------|---------------|
| 1 | Critical | file.py:42 | SQL injection via string formatting | Use parameterized queries |

### Summary
- Files reviewed: [N]
- Critical: [N] | High: [N] | Medium: [N] | Low: [N]
- Gate: PASS / FAIL (fails on Critical or High)
```

Focus on **exploitable** vulnerabilities, not theoretical risks. Provide concrete
recommendations with code examples when possible.
