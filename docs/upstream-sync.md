# Upstream Sync — Reference

Full procedure behind the `/upstream-sync` skill. **Read when syncing an upstream release.**

This fork shares no git ancestry with superpowers — it was bootstrapped by copying files into a
marketplace layout (see `adr/002-no-remote-upstream-sync.md`). There is no remote and no merge base.
Sync by diffing two upstream refs on GitHub and porting the delta by hand.

## Resolve the refs
A sync is bounded by two upstream refs — tags (`v6.0.3`) or SHAs:
- **base** — the last synced point. Defaults to the **Last synced** anchor in `customizations.md`.
- **head** — the new release to sync to.
- List candidates: `gh api repos/obra/superpowers/tags --jq '.[].name'`.

If either ref is unknown, ask before proceeding.

## Pull the upstream delta (no remote)
`gh api repos/obra/superpowers/compare/<base>...<head>` returns a `files[]` array, each with
`filename`, `status` (added/modified/removed/renamed), and `patch`. For the raw unified diff add
`-H "Accept: application/vnd.github.v3.diff"`. No `git remote add`, no `git fetch` — nothing enters
the local object store. A wide catch-up range can exceed one page of files; paginate with `?page=N`
(or use the raw diff) if `.files` looks capped.

## Translate the path
Upstream is a single plugin at its repo root; this fork nests it. Translate by zone:
- **Plugin payload** (`skills/`, `agents/`, `hooks/`, `.claude-plugin/plugin.json`, …) →
  `plugins/joe-bag-of-tricks/<p>`.
- **Repo-level files** (`CLAUDE.md`, `AGENTS.md`, `README.md`, `.claude-plugin/marketplace.json`, …)
  stay at the fork repo root.

Classify and apply on the translated path. Skip upstream paths the fork intentionally drops (harness
dirs, `tests/`, `scripts/`). Fork-original files have no upstream counterpart.

## The diff-driven sweep
For each changed upstream path, read the WHOLE patch and resolve by the fork file's state in
`customizations.md`:

- **vendored** → take upstream's head version
  (`gh api repos/obra/superpowers/contents/<p>?ref=<head>`, or apply the patch).
- **patched** → reconcile upstream's hunks with the fork delta by hand. `git apply --3way` on the
  path-translated patch (fetch the upstream base blob for that one file) recovers most of it. If
  conflicts recur on the same block each sync, lift your delta into a sidecar file the SKILL.md
  references.
- **replaced** → never apply. Read the upstream delta for ideas worth porting by hand; record what
  you ported (or chose not to). You own the file.

## New upstream files
Classify before vendoring. Verify license compatibility per `licensing.md`; record source + license
in `customizations.md`. Refuse anything unknown or incompatible.

## Finishing
- Update every touched row in `customizations.md`, and set **Last synced** to the head ref — this
  explicit anchor is what keeps the next sync's diff small; it replaces git's merge-base memory.
- Run `claude plugin validate` and a `claude --plugin-dir .` smoke load.
- Squash-merge the `sync/upstream-vX.Y.Z` branch via `finishing-a-development-branch`, like any
  other feature branch. There is no upstream ancestry to preserve, so no special merge handling.
