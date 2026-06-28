# Upstream Sync — Reference

Full procedure behind the `/upstream-sync` skill. **Read when syncing an upstream release tag.**

## Adding / tracking an upstream
- `git remote add <name> <url>` (e.g. `upstream` → github.com/obra/superpowers).
- Sync against **release tags**, not branches: `git fetch <name> --tags`.

## The diff-driven sweep
For each path where `git diff <prev-tag>..<new-tag> -- <path>` is non-empty, read the WHOLE
diff and resolve by the file's state in `customizations.md`:

- **vendored** → accept upstream's version.
- **patched** → three-way diff-merge; hand-resolve only overlapping hunks. If conflicts recur
  on the same block each sync, lift your delta into a sidecar file the SKILL.md references.
- **replaced** → never merge. Read the upstream delta for ideas worth porting by hand; record
  what you ported (or chose not to). You own the file.

## Conflict-resolution shortcuts
- `git checkout --theirs <path>` for vendored, `--ours` for replaced, then `git add`.
- Hand-edit only `patched` overlaps.

## New upstream files
Classify before vendoring. Verify license compatibility per `licensing.md`; record source +
license in `customizations.md`. Refuse anything unknown or incompatible.

## Finishing
Merge as a real merge commit (never squash). Run `claude plugin validate` and a
`claude --plugin-dir .` smoke load before opening the sync PR.
