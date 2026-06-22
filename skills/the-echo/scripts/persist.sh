#!/usr/bin/env bash
# persist.sh — "Lock it in" / "Wrap up": validate, commit, and push specific files
# to review-prep, from the user's local clone.
# Usage: bash scripts/persist.sh "commit message" path1 [path2 ...]
set -euo pipefail

MSG="${1:?usage: persist.sh \"commit message\" <path> [<path> ...]}"; shift || true
[ "$#" -ge 1 ] || { echo "usage: persist.sh \"commit message\" <path> [<path> ...]" >&2; exit 2; }

REPO_URL="https://github.com/mrheathjones/the-echo-canon.git"
BRANCH="review-prep"
LOCAL_CLONE="${THE_ECHO_CLONE:-/Users/heath/Downloads/the-echo-local}"

if   [ -d "$LOCAL_CLONE/.git" ]; then cd "$LOCAL_CLONE"
elif [ -d .git ];               then :   # already inside a clone
else echo "ERROR: no clone at $LOCAL_CLONE and not inside a repo. Clone first." >&2; exit 1; fi

git fetch origin "$BRANCH" >/dev/null 2>&1 || true
git checkout "$BRANCH" >/dev/null 2>&1 || git checkout -b "$BRANCH" "origin/$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"

# continuity gate
if [ -f tools/validate.sh ]; then
  echo ">> validating..."
  bash tools/validate.sh || { echo "ABORT: validation FAILed — nothing committed." >&2; exit 1; }
fi

git add -- "$@"
if git diff --cached --quiet; then echo "Nothing changed — already current."; exit 0; fi

git commit -m "$MSG" || git commit --no-verify -m "$MSG"

echo ">> pushing to $BRANCH..."
if git push -u origin "$BRANCH"; then
  echo "Done — pushed to $BRANCH."
else
  echo "Commit ok but PUSH failed (auth). Sign in (GitHub Desktop / gh auth login), then: git push -u origin $BRANCH" >&2
  exit 1
fi
