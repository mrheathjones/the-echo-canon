#!/usr/bin/env bash
###############################################################################
# tools/build_bible.sh — regenerate MASTER_CANON_BIBLE.md from canon/
#
# The bible is a DERIVED artifact: this script rolls up every file under canon/
# into one document, in a sensible order, with a "do not edit" banner. Because
# it always includes *every* canon/ file (ordered where known, appended where
# not), the bible can't silently drift out of sync with canon.
#
# Usage:
#   bash tools/build_bible.sh        # writes MASTER_CANON_BIBLE.md
# Then review the diff and commit. (The .docx/.pdf copies are NOT regenerated.)
###############################################################################
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
cd "$ROOT"
[ -d canon ] || { echo "ERROR: no canon/ found in $ROOT" >&2; exit 2; }

OUT="MASTER_CANON_BIBLE.md"
DATE="$(date +%Y-%m-%d)"

title_of(){ local t; t="$(grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# *//')"; [ -n "$t" ] || t="$(basename "$1" .md)"; printf '%s' "$t"; }

# preferred section order (missing files are skipped)
ORDER=(
  canon/SERIES_IDENTITY.md
  canon/00_SERIES_DECISIONS_LOCKED.md
  canon/THEMES.md
  canon/world/echo/ECHO_OVERVIEW.md
  canon/world/echo/ATTUNEMENT.md
  canon/world/echo/ECHO_MECHANICS_RESOLUTION.md
  canon/world/echo/MANIFESTATIONS_AND_CREATURES.md
  canon/world/echo/THE_GRAY_AND_HOLLOWS.md
  canon/world/accord/ACCORD_OVERVIEW.md
  canon/world/accord/MOTTO.md
  canon/world/accord/POWER_STRUCTURE.md
  canon/world/accord/PATHS_FACTIONS.md
  canon/world/accord/STRUCTURE_OPEN.md
  canon/story/BOOK_1_SPINE.md
  canon/story/BOOK_1_FOUNDATION.md
  canon/characters/hale-family/HALE_FAMILY.md
  canon/characters/hale-family/LUCAS_HALE.md
  canon/characters/hale-family/NOLAN_HALE.md
  canon/characters/hale-family/NOLAN_LOVABILITY_GUARDRAILS.md
  canon/characters/hale-family/EMMA_HALE.md
  canon/characters/hale-family/JACK_HALE_II.md
  canon/characters/hale-family/DYLAN_HALE.md
  canon/characters/hale-family/DAVID_HALE.md
  canon/characters/hale-family/RACHEL_HALE.md
  canon/characters/hale-family/DINNER_CULTURE.md
  canon/characters/hale-family/HUMOR_AND_VOICE.md
  canon/characters/hale-family/OWN_IT.md
  canon/characters/hale-family/BIGS_AND_LITTLES.md
  canon/characters/hale-family/JACK_FOOD_TEXTS.md
  canon/characters/hale-family/GRAMPS_GRAMS_STORE_RUNS.md
  canon/characters/hale-family/RECIPE_INHERITANCE.md
  canon/characters/friend-group/FRIEND_GROUP_ENGINE.md
  canon/characters/friend-group/FRIEND_GROUP_OVERVIEW.md
  canon/characters/friend-group/MAYA.md
  canon/characters/friend-group/ZOE.md
  canon/characters/friend-group/MASON.md
  canon/characters/friend-group/ELI.md
  canon/characters/accord/NATHAN_WHITMORE_CURATOR.md
  canon/characters/accord/SARAH_WHITMORE.md
  canon/characters/accord/ABIGAIL_ABBY_WHITMORE.md
  canon/characters/accord/ADRIAN_MERCER_ARCHITECT.md
  canon/characters/accord/ADRIAN_WOODWORKING.md
  canon/characters/accord/DEVON_CROSS.md
  canon/relationships/MAYA_AT_THE_HALE_HOUSE.md
  canon/locations/THE_BARN_AND_POND.md
  canon/timeline/FOUNDING_TRIO_TIMELINE.md
  canon/VISUAL_LANGUAGE.md
  canon/NAME_REGISTRY.md
  canon/OPEN_QUESTIONS.md
  canon/SUPERSEDED_ARCHIVED.md
  canon/CHANGELOG.md
)

# build final ordered list: known order first, then any remaining canon/*.md
declare -A SEEN=()
FINAL=()
for f in "${ORDER[@]}"; do
  if [ -f "$f" ] && [ -z "${SEEN[$f]:-}" ]; then FINAL+=("$f"); SEEN[$f]=1; fi
done
while IFS= read -r f; do
  if [ -z "${SEEN[$f]:-}" ]; then FINAL+=("$f"); SEEN[$f]=1; fi
done < <(find canon -type f -name '*.md' | sort)

# write the bible
{
  echo "<!-- GENERATED FILE — DO NOT EDIT. Rebuilt from canon/ by tools/build_bible.sh on ${DATE}."
  echo "     Edit the files under canon/ and re-run the script; hand edits here are overwritten. -->"
  echo
  echo "# The Echo — Master Canon Bible (generated rollup)"
  echo
  echo "_Assembled automatically from the \`canon/\` source files. **Do not edit by hand** — edit \`canon/\` and run \`tools/build_bible.sh\`._"
  echo
  echo "_Generated: ${DATE} · ${#FINAL[@]} source files._"
  echo
  echo "## Contents"
  echo
  i=0
  for f in "${FINAL[@]}"; do i=$((i+1)); echo "${i}. $(title_of "$f")  —  \`${f}\`"; done
  echo
  for f in "${FINAL[@]}"; do
    echo
    echo "---"
    echo
    echo "<!-- source: ${f} -->"
    echo
    cat "$f"
    echo
  done
} > "$OUT"

echo "Wrote ${OUT} from ${#FINAL[@]} canon files."
echo "Review the diff, then commit. (Remember: MASTER_CANON_BIBLE.docx/.pdf are not regenerated here.)"
