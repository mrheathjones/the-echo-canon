#!/usr/bin/env bash
# orient.sh — "Let's pick up <book>": clone-or-pull the repo on review-prep and
# print where we left off (journal + book spine + recent changes + continuity status).
# Usage: bash scripts/orient.sh ["Book 1" | "The Echo"]
set -uo pipefail

BOOK="${1:-The Echo}"
REPO_URL="https://github.com/mrheathjones/the-echo-canon.git"
BRANCH="review-prep"
LOCAL_CLONE="${THE_ECHO_CLONE:-/Users/heath/Downloads/the-echo-local}"

if   [ -d "$LOCAL_CLONE/.git" ]; then cd "$LOCAL_CLONE"; git fetch origin "$BRANCH" >/dev/null 2>&1 || true
elif [ -d .git ];               then :   # already inside a clone
else WORK="$(mktemp -d)"; git clone --quiet "$REPO_URL" "$WORK/the-echo-canon"; cd "$WORK/the-echo-canon"; fi

git checkout "$BRANCH" >/dev/null 2>&1 || git checkout -b "$BRANCH" "origin/$BRANCH" >/dev/null 2>&1 || true
git pull --quiet >/dev/null 2>&1 || true

echo "==================== WHERE WE LEFT OFF (journal) ===================="
if [ -f notes/THE_ECHO_CONTEXT_JOURNAL.md ]; then sed -n '1,400p' notes/THE_ECHO_CONTEXT_JOURNAL.md
else echo "(no journal yet — start one with 'wrap up')"; fi

echo
echo "==================== BOOK SPINE: $BOOK ===================="
case "$(printf '%s' "$BOOK" | tr 'A-Z' 'a-z')" in
  *"book 2"*) SPINE="canon/story/BOOK_2_SPINE.md" ;;
  *"book 1"*|*"book one"*|*"the echo"*|"") SPINE="canon/story/BOOK_1_SPINE.md" ;;
  *) SPINE="$(ls canon/story/*SPINE*.md 2>/dev/null | head -1)" ;;
esac
if [ -n "${SPINE:-}" ] && [ -f "$SPINE" ]; then sed -n '1,200p' "$SPINE"
else echo "(no spine file found for '$BOOK')"; fi

echo
echo "==================== RECENT CHANGES ===================="
git log --oneline -10 2>/dev/null || echo "(no git log)"

echo
echo "==================== CONTINUITY STATUS ===================="
if [ -f tools/validate.sh ]; then bash tools/validate.sh 2>/dev/null | tail -20; else echo "(tools/validate.sh not present)"; fi

echo
echo "Oriented on '$BRANCH'. Next: load references/craft-guardrails.md and report the single next move from the journal."
