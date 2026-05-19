# Restore — Re-create Symlinks on a New Machine

When `--restore` is passed (new machine, fresh clone of the second-brain repo).

## Procedure

1. Read `{vault_path}/.vault-config.md` to get the list of `knowledge_vaults`
2. For each vault in the list:
   - Check if `path` exists on this machine:
     ```bash
     [ -d "{vault.path}" ] && echo "FOUND: {vault.name}" || echo "MISSING: {vault.name}"
     ```
   - If found: create symlink:
     ```bash
     ln -s "{vault.path}" "{brain_path}/knowledge/{vault.name}"
     ```
   - If not found: warn and skip:
     ```
     ⚠ Vault "{vault.name}" not found at {vault.path}.
       Clone it first, then re-run /setup --restore.
     ```
3. Verify all symlinks:
   ```bash
   for LINK in "{brain_path}"/knowledge/*/; do
     [ -L "${LINK%/}" ] && [ -d "$LINK" ] && echo "OK: $(basename $LINK)" || echo "BROKEN: $(basename $LINK)"
   done
   ```
4. Brief with status:
   ```
   RESTORE COMPLETE

   [x] {vault-a}: linked
   [x] {vault-b}: linked
   [ ] {vault-c}: NOT FOUND at {path} — clone and re-run

   Run /setup --add-vault to link vaults at different paths on this machine.
   ```

## When Paths Differ Between Machines

If the user has vaults at different paths on this machine (e.g., company laptop
vs personal), they can:

1. Run `/setup --restore` (will warn about missing paths)
2. Run `/setup --add-vault` with the correct local path for each missing vault
3. The config will update with the new path for this machine

The `.vault-config.md` records the original path. If a vault is re-linked at a
different path, update the `path` field in config so future restores work.
