# Add Vault — Link Additional Knowledge Vault

When `--add-vault` is passed or the user asks to link a new vault to an
existing second-brain.

## Procedure

1. Read existing config from `{vault_path}/.vault-config.md`
2. Run the vault linking interview:
   - **Path**: "Full path to the vault (e.g., ~/Documents/obsidian-lizard-brain)"
     - Validate: directory exists, contains `.md` files
   - **Display name**: "Short name for this vault (used as symlink name)"
     - Validate: kebab-case, no conflicts with existing names in `knowledge/`
   - **Domain description**: "What domain does this vault cover? (one sentence)"
   - **Rules file detection**: Auto-detect rules files:
     ```bash
     find "$VAULT_PATH" -maxdepth 2 -name "*RULES*" -o -name "CLAUDE.md" | head -5
     ```
     If found: ask which governs note creation. If not: use defaults.
3. Create symlink:
   ```bash
   ln -s "{vault_absolute_path}" "{brain_path}/knowledge/{display_name}"
   ```
4. Verify symlink resolves:
   ```bash
   [ -d "{brain_path}/knowledge/{display_name}" ] && echo "OK" || echo "FAIL: broken symlink"
   ```
5. Update `.vault-config.md` frontmatter — append to `knowledge_vaults` list:
   ```yaml
   - name: {display_name}
     path: {absolute_path}
     symlink: knowledge/{display_name}
     domain: "{domain_description}"
     rules_file: "{rules_file_path_or_null}"
     writable: true
   ```
6. Update `.claude/obsidian-knowledge-management.local.md` vault count
7. Brief: "Added {name} ({domain}) to your second brain."

## Error Handling

- **Symlink target doesn't exist**: Don't create broken symlinks. Warn and skip.
- **Name collision in knowledge/**: Suggest alternative name or ask user to rename.
- **Vault already linked**: Detect existing symlink, skip or update if path changed.
- **Permission denied**: Suggest checking directory permissions.
