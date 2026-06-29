# ADR-002: No-Remote Tag-Diff Model for Upstream Sync

## Context

This fork shares **no git ancestry** with `obra/superpowers`. It was bootstrapped by copying
upstream files into a marketplace layout (`plugins/joe-bag-of-tricks/...`), not by forking git
history. The repo's whole history is a handful of commits rooted at the initial plugin commit.

The original `upstream-sync` skill and `docs/upstream-sync.md` assumed the standard downstream-fork
model: superpowers added as a git remote with a shared merge base. Its procedure was
`git remote add upstream`, `git fetch upstream --tags`, `git diff <prev-tag>..<new-tag>`, then
"merge as a real merge commit (never squash) to preserve ancestry."

Every one of those assumptions is structurally false here:

1. **No merge base.** Git has no common ancestor to reason from; a naive fork-vs-upstream diff
   reports every file as added.
2. **Paths are shifted.** Upstream `skills/x/SKILL.md` lives at
   `plugins/joe-bag-of-tricks/skills/x/SKILL.md` in the fork. Git merges by path, so a real merge
   would read every file as "upstream deleted `skills/x`, fork added `plugins/.../skills/x`."
3. **The fork is mostly `replaced`.** Most interesting files are owned re-expressions, plus
   fork-original skills (record-decision, readme-sync, writing-agents) with no upstream counterpart.
   A 3-way merge would auto-apply upstream edits into `replaced` files — the opposite of intent.
4. **Upstream harness dirs are deliberately stripped** (`.codex-plugin`, `gemini-extension.json`,
   etc.). A real merge would keep re-introducing them.

The git-merge model would therefore produce *more* cleanup than a manual port, not less.

## Decision

Adopt a no-remote, diff-driven port model. Upstream is a feed of changes pulled from GitHub, never
a remote merged into this repo.

### Diff source

Get the per-file upstream delta from the GitHub compare API:
`gh api repos/obra/superpowers/compare/<base>...<head>` (per-file `status` + `patch`), or the raw
unified diff via the `Accept: application/vnd.github.v3.diff` header. No remote is added; no upstream
objects are fetched into the local store.

### Inputs

The operator provides the **base** and **head** refs (tags like `v5.1.0`/`v6.0.3`, or SHAs). If
they are not provided, ask — and offer `gh api repos/obra/superpowers/tags` to list candidates.

### Path translation

Upstream `<p>` maps to fork `plugins/joe-bag-of-tricks/<p>`. Classification and application operate
on the translated fork path.

### Classification (unchanged)

Each touched file is resolved by its state in `docs/customizations.md`
(vendored / patched / replaced), keyed on fork paths.

### Anchor

Record the synced **head** ref as the next sync's base. This explicit anchor replaces git's
merge-base memory: each sync diffs `lastSynced...newRef`, a small targeted delta, never re-litigating
already-resolved changes.

### Merge

A sync is an ordinary `sync/upstream-vX.Y.Z` feature branch, squash-merged via
`finishing-a-development-branch` like any other branch. The previous "never squash a sync / real
merge commit to preserve ancestry" rule is retired — there is no ancestry to preserve.

## Trade-offs

**Chosen: no-remote tag-compare port**

- Works with zero shared ancestry; no fabricated merge base.
- GitHub-native — literally "diff in tags on github.com/obra/superpowers."
- Survives the path shift and the `replaced`-heavy profile, which a git merge cannot.
- The explicit anchor ref + `customizations.md` together provide what git's merge-base bookkeeping
  would have: "only look at what changed since last sync" plus "how each file is resolved."
- Squash-merge keeps sync history consistent with every other branch.

**Rejected: git-merge / shared-ancestry model**

- Requires a merge base that does not exist; faking one needs a history rewrite.
- Path translation defeats git's 3-way merge (rename/add/delete storm every sync).
- Auto-merges upstream into `replaced` files — the opposite of intent.
- Keeps re-introducing stripped harness dirs.

**Rejected: local fetch-by-URL of the two refs, then `git diff`**

- Buys full `git diff` / `git apply --3way`, but pulls upstream objects into the repo and is not
  "diff on GitHub."
- Its only real advantage is `patched`-file reconciliation, currently one file.

**Cost accepted: hand-reconciliation of `patched` files**

- Without a merge base we lose free 3-way conflict markers on `patched` files. `gh compare` returns
  real patches, so `git apply --3way` (fetching just that file's upstream base blob) recovers most
  of the convenience. Bounded — there is currently one `patched` file.
