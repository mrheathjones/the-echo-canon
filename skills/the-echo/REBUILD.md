# Rebuilding the `the-echo` skill

This folder is the **source** of the `the-echo` skill, versioned here so it's portable and
rebuildable. The installable `.skill` file is just this folder packaged.

## Rebuild the installable `.skill`
- With Anthropic's skill-creator tooling (run from the skill-creator directory):
  ```
  python -m scripts.package_skill skills/the-echo <output-dir>
  ```
- Or manually — a `.skill` is a zip whose root contains `the-echo/`:
  ```
  cd skills && zip -r ../the-echo.skill the-echo
  ```
Then upload/re-install the `.skill` in your skills library.

## What it does
Once installed, a session responds to three commands:
- **"let's pick up The Echo"** — orient from the repo, report where we left off
- **"lock it in"** — persist current work to the repo (validated)
- **"let's wrap up"** — write session state to the journal for next time

## Keep it in sync
This is process + craft only — **no canon** lives here (canon stays in `canon/`). If you change
the skill in your library, update these files too (or vice-versa) so the repo copy remains the
source of truth for the skill.
