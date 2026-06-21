#!/usr/bin/env bash
###############################################################################
# tools/validate.sh — continuity gate for the-echo-canon
#
# Runs a set of cheap, high-signal checks against canon/ to catch the kinds of
# drift we keep hitting by hand (duplicate names, references to removed files,
# retired surnames, a hand-edited bible). Run it before every push.
#
#   FAIL  = a real break; exit code 1 (use this to block a push).
#   WARN  = worth a human look, not necessarily wrong; does not block.
#
# Usage:
#   bash tools/validate.sh
# Exit 0 if no FAIL (warnings allowed), 1 if any FAIL.
###############################################################################
set -uo pipefail

# --- locate repo root (the dir that contains canon/) -------------------------
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
cd "$ROOT"
if [ ! -d canon ]; then
  echo "ERROR: can't find canon/ (looked in $ROOT)." >&2
  exit 2
fi

FAILS=0; WARNS=0
fail(){ echo "  ✗ FAIL: $*"; FAILS=$((FAILS+1)); }
warn(){ echo "  ! WARN: $*"; WARNS=$((WARNS+1)); }
ok(){   echo "  ✓ ok:  $*"; }

# directories that may or may not exist on a given branch.
# NOTE: source/ is raw archival transcript material (old/hypothetical names and
# paths), never authored canon — it is deliberately never validated.
SCAN_DIRS=()
for d in canon drafts review notes; do [ -d "$d" ] && SCAN_DIRS+=("$d"); done

echo "── 1. required files ──────────────────────────────────────────────"
for f in canon/SERIES_IDENTITY.md canon/NAME_REGISTRY.md canon/SUPERSEDED_ARCHIVED.md; do
  if [ -f "$f" ]; then ok "$f"; else fail "missing required file $f"; fi
done
if [ -f canon/story/BOOK_1_SPINE.md ] || [ -f canon/story/BOOK_1_FOUNDATION.md ]; then
  ok "a Book 1 spine file is present"
else
  fail "no Book 1 spine file (expected canon/story/BOOK_1_SPINE.md)"
fi

echo "── 2. retired / forbidden tokens ──────────────────────────────────"
# Maya's surname must never collide with the Whitmore founders again
if grep -rIl "Maya Whitmore" "${SCAN_DIRS[@]}" >/dev/null 2>&1; then
  fail "'Maya Whitmore' appears (retired surname collision with the founders)"
else ok "no 'Maya Whitmore' collision"; fi
# placeholder names that still need replacing → surface as warnings
if grep -rIl "Jonesepies" "${SCAN_DIRS[@]}" >/dev/null 2>&1; then
  warn "'Jonesepies' placeholder still present (needs a Hale-compatible name)"
fi

echo "── 3. dangling canon/ path references (canon/ only) ───────────────"
# Cross-links inside canon/ must resolve. Skip the two history files whose job
# is to mention removed paths, and exempt paths known to be intentionally gone.
KNOWN_REMOVED=" canon/story/BOOK_1_FOUNDATION.md "
DANGLING=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  [ -f "$ref" ] && continue
  case "$KNOWN_REMOVED" in *" $ref "*) continue;; esac
  fail "dangling reference to missing path: $ref"; DANGLING=$((DANGLING+1))
done < <(grep -rhoE 'canon/[A-Za-z0-9_./-]+\.md' canon \
            --exclude=CHANGELOG.md --exclude=SUPERSEDED_ARCHIVED.md 2>/dev/null | sort -u)
[ "$DANGLING" -eq 0 ] && ok "all canon/ cross-links resolve"

echo "── 4. name registry — cross-section identity collisions ───────────"
REG=canon/NAME_REGISTRY.md
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
# emit: given<TAB>section<TAB>namepart  (namepart = name stripped of role/alias/note)
awk '
  /^[A-Z0-9].*:[ \t]*$/ { sect=$0; sub(/:[ \t]*$/,"",sect); next }
  /^- / {
    line=$0; sub(/^- /,"",line)
    sub(/ \/ .*/,"",line); sub(/ - .*/,"",line); sub(/[ \t]+\*\(.*/,"",line)
    gsub(/^[ \t]+|[ \t]+$/,"",line)
    if (line=="" || sect=="") next
    g=line; sub(/[ \t].*/,"",g); gsub(/[“”"]/,"",g)
    if (g=="") next
    print g "\t" sect "\t" line
  }' "$REG" > "$TMP"
COLL=0
for g in $(cut -f1 "$TMP" | sort -u); do
  secs=$(awk -F'\t' -v g="$g" '$1==g{print $2}' "$TMP" | sort -u | wc -l | tr -d ' ')
  fulls=$(awk -F'\t' -v g="$g" '$1==g{print $3}' "$TMP" | sort -u | wc -l | tr -d ' ')
  if [ "$secs" -ge 2 ] && [ "$fulls" -ge 2 ]; then
    detail=$(awk -F'\t' -v g="$g" '$1==g{print $3" ["$2"]"}' "$TMP" | sort -u | paste -sd'; ' -)
    warn "name '$g' used across sections as different people: $detail"
    COLL=$((COLL+1))
  fi
done
[ "$COLL" -eq 0 ] && ok "no cross-section name collisions in the registry"

echo "── 5. master bible is a generated rollup ──────────────────────────"
if [ -f MASTER_CANON_BIBLE.md ]; then
  if grep -q "GENERATED FILE — DO NOT EDIT" MASTER_CANON_BIBLE.md; then
    ok "MASTER_CANON_BIBLE.md is a generated rollup"
  else
    warn "MASTER_CANON_BIBLE.md is not generated (may be hand-edited/stale); rebuild with tools/build_bible.sh"
  fi
fi

echo "───────────────────────────────────────────────────────────────────"
echo "validate: $FAILS fail, $WARNS warn"
[ "$FAILS" -eq 0 ] || { echo "BLOCK: fix FAILs before pushing."; exit 1; }
echo "OK to push (warnings are advisory)."
exit 0
