---
name: setup
description: >
  Set up a second-brain vault with personal orchestration (self/, ops/) and
  optional symlinked domain-specific knowledge vaults. Interviews the user,
  scaffolds directories, creates symlinks, initialises git, and writes config.
  Also supports linking additional knowledge vaults to an existing second-brain.
argument-hint: "[vault-path] [--restore] [--add-vault]"
allowed-tools: Bash Read Write Edit
---

# setup -- Second Brain Onboarding

Walk the user from zero to a fully configured second-brain in one session.
The second-brain is a personal orchestration vault that links to one or more
shared domain-specific knowledge vaults.

## Architecture

```
~/Documents/{brain-name}/           ← the second-brain (open in Obsidian)
├── self/                           ← identity, goals, methodology
├── ops/                            ← queue, reminders, sessions
├── inbox/                          ← unsorted captures, routed later
└── knowledge/
    ├── personal/                   ← cross-domain synthesis (yours alone)
    ├── {domain-a}/ → symlink       ← shared vault A
    └── {domain-b}/ → symlink       ← shared vault B
```

## When to Use

- First time using the plugin (no config file exists)
- Adding a new domain vault to an existing second-brain (`--add-vault`)
- Restoring on a new machine (re-creating symlinks from config) (`--restore`)
- The plugin fired a vault-not-found gate (missing config)

## When NOT to Use

- Day-to-day operations (use `/orient`, `/next`, `/queue`, `/wrap`)
- Vault maintenance within a domain (use `/maintain`)
- Knowledge retrieval (use `/retrieve`)

---

## Mode Detection

1. If `--restore` argument: jump to **Phase: Restore**
2. If `--add-vault` argument: jump to **Phase: Add Vault**
3. If config exists at `.claude/obsidian-knowledge-management.local.md`: offer to add a vault or re-run full setup
4. Otherwise: run full setup from Phase 1

---

## Phase 1: Interview

### Step 1 -- Brain Name

Ask: **"What would you like to call your second brain? (default: second-brain)"**

- Used as the directory name: `~/Documents/{brain-name}/`
- Validate: lowercase, hyphens OK, no spaces or special chars
- If directory exists and contains `.vault-config.md`, it's already set up — offer add-vault or reconfigure

### Step 2 -- Brain Location

Ask: **"Where should it live? (default: ~/Documents/{brain-name})"**

- Expand `~` to home directory
- If directory doesn't exist, confirm creation

### Step 3 -- Knowledge Vaults

Present the choice:

```
How would you like to set up your knowledge layer?

  (1) Link existing shared vault(s) — I already have Obsidian vaults with domain knowledge
  (2) Start fresh — create a new knowledge vault from scratch (zettelkasten/flat/para)
  (3) Both — link existing vault(s) AND create a new one
  (4) Skip for now — I'll just use personal/ for my own notes
```

#### If linking existing vaults (repeatable):

For each vault:

1. **Path**: "Full path to the vault (e.g., ~/Documents/obsidian-lizard-brain)"
   - Validate: directory exists, contains `.md` files
2. **Display name**: "Short name for this vault (used as symlink name, e.g., lizard-brain)"
   - Validate: kebab-case, no conflicts with existing names
3. **Domain description**: "What domain does this vault cover? (one sentence)"
   - Used by retrieval to route queries to the right vault
4. **Rules file detection**: Auto-detect rules files in the vault:
   ```bash
   find "$VAULT_PATH" -maxdepth 2 -name "*RULES*" -o -name "CLAUDE.md" | head -5
   ```
   - If found: "I found these rules files: {list}. Which governs note creation? (or: none)"
   - If not found: "No rules file detected. Notes written here will follow VAULT_RULES.md defaults."

Ask: **"Link another vault? (yes/no)"** — repeat until done.

#### If starting fresh:

Run the standard vault scaffold flow (zettelkasten/flat/para preset) but target
`{brain_path}/knowledge/{name}/` instead of the root. This creates an OWNED
domain vault (not symlinked, fully writable, versioned with the brain).

### Step 4 -- Observer Preference

Ask: **"Enable the session observer? It captures patterns during work sessions for later reflection. (yes/no, default: yes)"**

### Step 5 -- Auto-commit Preference

Ask:

```
How should session state (ops/) be version controlled?

  (1) Auto-commit only — commits at session end, you push manually
  (2) Auto-commit and push — fully automatic, pushes to remote after each session
  (3) Manual — no automatic commits, you manage git yourself
```

---

## Phase 2: Scaffold

### Create Directory Structure

```bash
BRAIN="{brain_path}"
mkdir -p "$BRAIN/self"
mkdir -p "$BRAIN/ops/queue"
mkdir -p "$BRAIN/ops/sessions"
mkdir -p "$BRAIN/inbox"
mkdir -p "$BRAIN/knowledge/personal"
```

### Create Symlinks

For each linked vault:

```bash
ln -s "{vault_absolute_path}" "$BRAIN/knowledge/{display_name}"
```

Verify each symlink resolves:

```bash
[ -d "$BRAIN/knowledge/{display_name}" ] && echo "OK: {display_name}" || echo "FAIL: {display_name} symlink broken"
```

### Seed Self Files

**Write `self/goals.md`:**

```markdown
---
updated: {YYYY-MM-DD}
---

# Goals

## Active Threads

<!-- What you're currently focused on. Updated by /wrap at session end. -->

## Deferred

<!-- Parked items — not forgotten, just not now. -->

## Recently Completed

<!-- Cleared periodically. Gives a sense of progress. -->
```

**Write `self/methodology.md`:**

```markdown
---
updated: {YYYY-MM-DD}
---

# Methodology

How I work best. Accumulated from experience, updated as I learn.

## Operational Learnings

<!-- Patterns discovered through use. Added by /wrap when something works or fails. -->

## Preferences

<!-- Working style, tool preferences, communication patterns. -->
```

### Seed Ops Files

**Write `ops/reminders.md`:**

```markdown
---
updated: {YYYY-MM-DD}
---

# Reminders

<!-- Time-bound actions. Checked at session start by /orient. -->
<!-- Format: - [ ] YYYY-MM-DD: Description -->
<!-- Completed: - [x] YYYY-MM-DD: Description (done YYYY-MM-DD) -->
```

### Seed Personal Knowledge

**Write `knowledge/personal/README.md`:**

```markdown
# Personal Knowledge

Cross-domain synthesis and serendipitous connections. Notes here draw from
multiple knowledge vaults and represent your own original thinking.

## Linking Rules

- MAY link to any note in any knowledge vault (shared or personal)
- Notes in shared vaults do NOT link back here
- Use standard [[wikilinks]] — Obsidian resolves across the whole vault tree
```

---

## Phase 3: Git Initialisation

```bash
BRAIN="{brain_path}"
cd "$BRAIN"

git init
```

**Write `.gitignore`:**

```gitignore
# Symlinked vaults are independently versioned
knowledge/*/
!knowledge/personal/

# Obsidian workspace state
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/graph.json

# OS files
.DS_Store
Thumbs.db
```

Note: `knowledge/*/` ignores all symlinked vault contents (they have their own repos).
The `!knowledge/personal/` exception ensures personal notes ARE tracked.

Initial commit:

```bash
git add -A
git commit -m "Initial second-brain scaffold"
```

---

## Phase 4: Write Plugin Config

### `.vault-config.md` (inside the brain)

Write `{brain_path}/.vault-config.md`:

```markdown
---
preset: orchestrated
created: {YYYY-MM-DD}
brain_name: {brain_name}
self_dir: self
ops_dir: ops
inbox_dir: inbox
personal_knowledge_dir: knowledge/personal
observer_enabled: {true|false}
auto_commit: {commit-only|commit-and-push|manual}

knowledge_vaults:
  - name: {display_name}
    path: {absolute_path}
    symlink: knowledge/{display_name}
    domain: "{domain_description}"
    rules_file: "{rules_file_path_or_null}"
    writable: true
---

# Second Brain Configuration

This file is read by the obsidian-knowledge-management plugin.
Edit the YAML frontmatter to update settings.

## Knowledge Vaults

{table of linked vaults with name, domain, and path}

## Link Rules

| From | To | Allowed |
|------|-----|---------|
| self/, ops/ | any knowledge vault | Yes |
| knowledge/personal/ | any knowledge vault | Yes |
| domain vault note | same domain vault | Yes |
| domain vault note | self/, ops/, personal/ | No |
| domain vault note | different domain vault | No |
```

### `.claude/obsidian-knowledge-management.local.md` (project-level)

```markdown
---
vault_path: {absolute_brain_path}
vault_preset: orchestrated
observer_enabled: {true|false}
auto_commit: {commit-only|commit-and-push|manual}
---

# Obsidian Knowledge Management - Local Configuration

Plugin configuration for this machine.

- **Brain**: {brain_name}
- **Path**: {vault_path}
- **Knowledge vaults**: {count} linked
- **Observer**: {enabled|disabled}
- **Auto-commit**: {mode}
```

---

## Phase 5: Verification

```bash
BRAIN="{brain_path}"

echo "=== Structure ==="
find "$BRAIN" -maxdepth 2 -type d | grep -v ".git" | sort

echo ""
echo "=== Symlinks ==="
find "$BRAIN/knowledge" -maxdepth 1 -type l -exec echo "OK: {}" \;

echo ""
echo "=== Config ==="
[ -f "$BRAIN/.vault-config.md" ] && echo "OK: .vault-config.md"
[ -f "$BRAIN/self/goals.md" ] && echo "OK: self/goals.md"
[ -f "$BRAIN/ops/reminders.md" ] && echo "OK: ops/reminders.md"

echo ""
echo "=== Git ==="
cd "$BRAIN" && git log --oneline -1
```

---

## Phase 6: Briefing

```
SETUP COMPLETE

[x] Brain: {brain_name} at {brain_path}
[x] Self: goals.md, methodology.md
[x] Ops: reminders.md, queue/, sessions/
[x] Knowledge: personal/ + {N} linked vault(s)
    {for each vault: "  - {name}: {domain}"}
[x] Git: initialised with .gitignore
[x] Observer: {enabled|disabled}
[x] Auto-commit: {mode}
[x] Config: .claude/obsidian-knowledge-management.local.md

Open ~/Documents/{brain_name}/ in Obsidian to see everything together.

NEXT STEPS:
- /orient — start a session (loads goals, reminders, queue)
- /queue add "..." — add your first task
- /retrieve "topic" — search across all linked knowledge
```

---

## Phase: Add Vault

See [references/add-vault.md](references/add-vault.md) for the full procedure.

Summary: interview for path/name/domain, create symlink, update config, verify.

---

## Phase: Restore

See [references/restore.md](references/restore.md) for the full procedure.

Summary: read config, re-create symlinks for each vault, warn about missing paths.

---

## Error Handling

- **Symlink target doesn't exist**: Don't create broken symlinks. Warn and skip.
- **Name collision in knowledge/**: Suggest alternative name or ask user to rename.
- **Permission denied**: Suggest checking directory permissions.
- **Vault already linked**: Detect existing symlink, skip silently or update if path changed.
- **Git not available**: Warn but continue. Git is recommended, not required.
