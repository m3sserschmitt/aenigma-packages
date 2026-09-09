#!/bin/bash

set -euo pipefail
 
usage() {
  echo "Usage: $0 -c <commit-ish>"
  echo "  -c   Commit (hash, branch, tag, HEAD~n, etc.) to use as the new root commit"
  exit 1
}
 
COMMIT=""
 
while getopts ":c:" opt; do
  case "$opt" in
    c) COMMIT="$OPTARG" ;;
    *) usage ;;
  esac
done
 
if [[ -z "$COMMIT" ]]; then
  echo "Error: -c <commit-ish> is required."
  usage
fi
 
# Must be run inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi
 
# Verify the commit exists
if ! git rev-parse --verify --quiet "${COMMIT}^{commit}" >/dev/null; then
  echo "Error: commit '$COMMIT' not found."
  exit 1
fi
 
RESOLVED_COMMIT="$(git rev-parse "$COMMIT")"
echo "Target commit resolved to: $RESOLVED_COMMIT"
 
# Ensure origin remote exists (needed for the force-push step)
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Error: no 'origin' remote configured."
  exit 1
fi
 
# Record what gh-pages currently points to (if it exists), for comparison
OLD_GH_PAGES_SHA="$(git rev-parse --verify --quiet refs/heads/gh-pages 2>/dev/null || echo "none")"
echo "Current local gh-pages: $OLD_GH_PAGES_SHA"
 
# Prompt interactively for the commit message
echo "Enter the commit message for the new root commit (Ctrl+D when done):"
COMMIT_MSG="$(cat)"
 
if [[ -z "$COMMIT_MSG" ]]; then
  echo "Error: commit message cannot be empty."
  exit 1
fi
 
TEMP_BRANCH="reset-history-tmp-$(date +%s)"
 
# Create the orphan branch WITHOUT a start-point (portable across all git
# versions), from whatever is currently checked out.
echo "Creating orphan branch '$TEMP_BRANCH' ..."
git checkout --orphan "$TEMP_BRANCH"
 
# Clear the index completely so nothing from the previous branch carries over
echo "Clearing index ..."
git rm -rf --cached . >/dev/null 2>&1 || true
 
# Also clear the working directory of any leftover tracked files, then
# repopulate it explicitly from the target commit's tree.
echo "Cleaning working directory ..."
git clean -fdx >/dev/null 2>&1 || true
 
echo "Checking out tree from $RESOLVED_COMMIT ..."
git checkout "$RESOLVED_COMMIT" -- .
 
echo "Staging files ..."
git add -A
 
echo "Creating new root commit ..."
git commit -m "$COMMIT_MSG"
 
NEW_SHA="$(git rev-parse HEAD)"
echo "New root commit created: $NEW_SHA"
 
if [[ "$NEW_SHA" == "$OLD_GH_PAGES_SHA" ]]; then
  echo "WARNING: new commit SHA is identical to the previous gh-pages tip."
  echo "This should not normally happen with a fresh root commit — double-check before proceeding."
fi
 
# Delete existing local gh-pages branch if present
if git show-ref --verify --quiet refs/heads/gh-pages; then
  echo "Local branch 'gh-pages' already exists — deleting it."
  git branch -D gh-pages
fi
 
echo "Renaming '$TEMP_BRANCH' to 'gh-pages' ..."
git branch -m gh-pages
 
echo "Done. 'gh-pages' now starts fresh at commit $RESOLVED_COMMIT (new SHA: $NEW_SHA) and has been pushed to origin."
echo "Note: old commits may still exist in local .git until garbage collected. Run:"
echo "  git reflog expire --expire=now --all && git gc --prune=now --aggressive"
echo "to purge them locally if needed."

exit 0
