---
name: upstream-sync
description: "Use when syncing a new upstream release into this fork, or before editing any inherited file. Diffs two upstream refs (tags/SHAs) via the GitHub compare API — NO remote — then ports changes by hand under vendored/patched/replaced classification. Authoring-only; not shipped. Invoke explicitly."
disable-model-invocation: true
---

# Upstream Sync

Bring upstream changes into this fork. The fork shares **no git ancestry** with superpowers — it
was bootstrapped by copying files into a marketplace layout — so there is no remote to merge and no
merge base. Instead, diff two upstream refs on GitHub and port the delta by hand. This skill edits
and deletes files; invoke it explicitly. Why this model: `@docs/adr/002-no-remote-upstream-sync.md`.

Source of truth is the **diff**, never memory. A file you think is pristine may carry a forgotten
tweak; a file you "only added beads to" may also have other edits. Classify on what the diff shows.
Full procedure and examples: `@docs/upstream-sync.md`.

## Inputs
Two upstream refs — **base** (last synced) and **head** (new release) — as tags (`v6.0.3`) or SHAs.
If not provided, ask. List candidates with `gh api repos/obra/superpowers/tags --jq '.[].name'`.
The base defaults to the **Last synced** anchor recorded in `@docs/customizations.md`.

## Per-Sync Procedure
1. Resolve base + head refs (ask if missing). Create branch `sync/upstream-vX.Y.Z`.
2. Pull the upstream delta — no remote:
   `gh api repos/obra/superpowers/compare/<base>...<head>` gives per-file `status` + `patch`
   (add `-H "Accept: application/vnd.github.v3.diff"` for the raw unified diff). A wide catch-up
   range can exceed one page of files — paginate with `?page=N` (or use the raw diff) if `.files`
   looks capped.
3. For each changed upstream path, translate it (see below), then act by its manifest state:
   - **vendored** — take upstream's head version wholesale
     (`gh api repos/obra/superpowers/contents/<p>?ref=<head>`).
   - **patched** — reconcile upstream's hunks with the fork delta by hand. `git apply --3way` on the
     path-translated patch (with the upstream base blob fetched for that one file) recovers most of it.
   - **replaced** — DO NOT apply. Read the upstream patch, decide whether to port any idea by hand,
     record the decision. You own the file; upstream is a feed of ideas.
4. New upstream files: classify and, before vendoring, verify license per `@docs/licensing.md`.
5. Update every touched row in `@docs/customizations.md` (state + source + license + reason(s)).
6. Record the synced **head** ref as the new **Last synced** anchor in `@docs/customizations.md` —
   this replaces git's merge-base memory so the next sync only diffs what changed since.
7. Validate: `claude plugin validate plugins/joe-bag-of-tricks` (path required; `.` would check
   only the marketplace manifest), then `.claude/scripts/verify-skills-load.sh` — a sync touches
   many skills at once, and this is the only check that every one of them still resolves and
   loads. It proves loading, not triggering; description drift that breaks *triggering* is not
   covered (`@docs/adr/006-defer-behavioral-evals.md`). Squash-merge the sync branch via
   `/joe-bag-of-tricks:finishing-a-development-branch`, like any other branch.

## Path Translation
This repo is a marketplace; upstream is a single plugin at its repo root. Translate by zone:
- **Plugin payload** (`skills/`, `agents/`, `hooks/`, `assets/`, `.claude-plugin/plugin.json`) →
  `plugins/joe-bag-of-tricks/<p>` (e.g. upstream `skills/x/SKILL.md` ↔ fork
  `plugins/joe-bag-of-tricks/skills/x/SKILL.md`).
- **Repo-level files** (`CLAUDE.md`, `AGENTS.md`, `README.md`, `LICENSE`,
  `.claude-plugin/marketplace.json`, `.github/`) stay at the fork repo root (`<p>` → `<p>`).

Skip upstream paths the fork intentionally drops (harness dirs, `tests/`, `scripts/`). Fork-original
files (record-decision, readme-sync, writing-agents, the PR/merge agents, …) have no upstream
counterpart — ignore them.

## Classifying a Modified File
- Diff concentrated in one block, additive → **patched**; consider lifting it to a sidecar file the
  SKILL.md references, so future merges stay clean.
- Diff smeared across the spine (checklist, process graph, inline commands) and divergence is
  substantial → **replaced**.
- "Why" may be a list, not one cause (e.g. `replaced: beads persistence + stricter model gate`).

## Adding Another Upstream
No remote needed. Record its GitHub `owner/repo` and a fork-point ref to seed the **Last synced**
anchor. Strip any harness dirs it ships that this fork doesn't carry. Verify license per
`@docs/licensing.md` before vendoring anything.

## Red Flags
- NEVER add superpowers (or any upstream) as a git remote or `git merge` it — no shared ancestry.
  Diff refs on GitHub and port by hand.
- NEVER apply an upstream change into a `replaced` file. Port ideas by hand, record what you did.
- NEVER assume a single concern (beads or otherwise) accounts for a file's full divergence.
- NEVER vendor a file whose license is unknown or incompatible.
