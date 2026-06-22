# The Echo — Workflow & Drift Rules
_Read this before any repo write._

## Single source of truth
Edit canon in `canon/` only. The master bible is a GENERATED rollup — never hand-edit
`MASTER_CANON_BIBLE.md`; edit `canon/` and run `tools/build_bible.sh`. The journal and any
review/scene packets are derived snapshots, not truth.

## Repo
- URL: `https://github.com/mrheathjones/the-echo-canon` (public)
- Branch: **`draft`** — do all work here; fold to `main` at milestones.
- Local clone (default): `/Users/heath/Downloads/the-echo-local` (override with env `THE_ECHO_CLONE`).
- Run scripts from inside the clone; they operate in place. Running a bare tool from elsewhere
  (e.g. CodeRunner's folder) fails because there's no repo there.

## Validate before every push
Run `tools/validate.sh`. **FAIL blocks a push** (missing required file; no Book 1 spine; the
retired `Maya Whitmore` collision; a broken cross-link inside `canon/`). **WARN is advisory**
(a `Jonesepies` placeholder; a first name used across registry sections as two different people,
like the two Sarahs; an ungenerated bible). `scripts/persist.sh` runs this gate automatically.

## Credentials — never
Never ask the user for a token or password, and never enter credentials yourself. Cloning a
public repo needs no auth; pushing uses the user's cached GitHub auth in their own clone. If a
push fails for auth, tell the user to sign in once via GitHub Desktop or `gh auth login` and run
`git push -u origin draft` themselves.

## Persisting work
**Preferred** (user's local clone with auth): write files into the clone, then
`bash scripts/persist.sh "<msg>" <paths…>`.

**Fallback** (no clone/auth, e.g. plain claude.ai with no code tool): generate a tested one-shot
bash script the user runs. Template:

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_URL="https://github.com/mrheathjones/the-echo-canon.git"
BRANCH="draft"
LOCAL_CLONE="${THE_ECHO_CLONE:-/Users/heath/Downloads/the-echo-local}"
if   [ -d "$LOCAL_CLONE/.git" ]; then cd "$LOCAL_CLONE"
elif [ -d "$LOCAL_CLONE" ] && [ -z "$(ls -A "$LOCAL_CLONE" 2>/dev/null)" ]; then git clone "$REPO_URL" "$LOCAL_CLONE"; cd "$LOCAL_CLONE"
elif [ ! -d .git ]; then git clone "$REPO_URL"; cd the-echo-canon; fi
git fetch origin "$BRANCH" >/dev/null 2>&1 || true
git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
# --- write files idempotently here:  mkdir -p <dir>; cat > "<path>" <<'EOF' … EOF ---
[ -f tools/validate.sh ] && { bash tools/validate.sh || { echo "validation failed"; exit 1; }; }
git add -A
git commit -m "<message>" || git commit --no-verify -m "<message>"
git push -u origin "$BRANCH"   # only this needs the user's auth
```
Rules for any script you generate: idempotent writes, run validate before commit, only the final
push needs auth, and never embed a credential.

## Bible
After canon changes: `bash tools/build_bible.sh`, then commit `MASTER_CANON_BIBLE.md`.
(The `.docx`/`.pdf` copies are not regenerated.)

## Branches
Keep one working branch (`draft`). Don't let feature branches accumulate competing truth.
