#!/usr/bin/env bash
set -euo pipefail

# Pre-push hook: review changed SKILL.md files using skill-reviewer
# Only reviews new or modified skill files compared to remote tracking branch

REPO_ROOT="$(git rev-parse --show-toplevel)"
REMOTE="${1:-origin}"
REMOTE_REF="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "${REMOTE}/main")"

# Find SKILL.md files that changed vs remote
CHANGED_SKILLS=$(git diff --name-only --diff-filter=AM "$REMOTE_REF"...HEAD -- '*/SKILL.md' 2>/dev/null || true)

if [ -z "$CHANGED_SKILLS" ]; then
  echo "pre-push: No SKILL.md changes to review."
  exit 0
fi

echo "pre-push: Reviewing changed skill files..."
echo "$CHANGED_SKILLS" | while read -r file; do
  echo "  - $file"
done

# Classify files as new or modified
NEW_FILES=""
MODIFIED_FILES=""

for file in $CHANGED_SKILLS; do
  if git cat-file -e "${REMOTE_REF}:${file}" 2>/dev/null; then
    MODIFIED_FILES="${MODIFIED_FILES}${file}:modified"$'\n'
  else
    NEW_FILES="${NEW_FILES}${file}:new"$'\n'
  fi
done

# Write metadata for the skill-reviewer
METADATA_FILE=$(mktemp)
{
  echo "# Changed skill files for review"
  echo "$NEW_FILES$MODIFIED_FILES" | grep -v '^$'
} > "$METADATA_FILE"

# Generate diff for modified files
DIFF_FILE=$(mktemp)
if [ -n "$MODIFIED_FILES" ]; then
  for file in $(echo "$MODIFIED_FILES" | cut -d: -f1 | grep -v '^$'); do
    echo "=== $file ===" >> "$DIFF_FILE"
    git diff "$REMOTE_REF"...HEAD -- "$file" >> "$DIFF_FILE"
    echo "" >> "$DIFF_FILE"
  done
fi

# Run Claude with skill-reviewer plugin
REVIEW_OUTPUT=$(mktemp)

claude --plugin-dir "${REPO_ROOT}/plugins/skill-reviewer" \
  --print \
  --allowedTools "Read,Grep,WebFetch" \
  -p "You are reviewing skill files before push. Read the metadata at ${METADATA_FILE} to see which files changed and whether they are new or modified. For modified files, the diff is at ${DIFF_FILE}. Follow the skill-reviewer skill instructions: use full review mode for new files, diff-focused mode for modified files. Output your review to stdout. If any Critical issues are found, end with EXIT_CODE=1. Otherwise end with EXIT_CODE=0." \
  > "$REVIEW_OUTPUT" 2>&1

# Display review
cat "$REVIEW_OUTPUT"

# Check if review found critical issues
if grep -q "EXIT_CODE=1" "$REVIEW_OUTPUT"; then
  echo ""
  echo "pre-push: BLOCKED — skill review found critical issues. Fix them before pushing."
  rm -f "$METADATA_FILE" "$DIFF_FILE" "$REVIEW_OUTPUT"
  exit 1
fi

rm -f "$METADATA_FILE" "$DIFF_FILE" "$REVIEW_OUTPUT"
echo "pre-push: Skill review passed."
exit 0
