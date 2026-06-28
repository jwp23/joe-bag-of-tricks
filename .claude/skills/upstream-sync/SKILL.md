---
name: upstream-sync
description: "Use when syncing a new upstream release tag into this fork, or before editing any inherited file. Owns first-run initialization, tag-merge, diff-driven classification (vendored/patched/replaced), and conflict resolution. Authoring-only — not shipped in the plugin."
disable-model-invocation: true
---

# Upstream Sync

Bring a new upstream release into this fork while preserving customizations. This skill does
git merges and deletes files — invoke it explicitly; it never runs on its own.

Source of truth is the **git diff**, never memory. A file you think is pristine may carry a
forgotten tweak; a file you "only added beads to" may also have other edits. Classify on what
the diff shows. Full procedure and examples: `@docs/upstream-sync.md`.

## Initialization (first run only)
1. Strip non-Claude-Code harnesses: remove `.codex-plugin`, `.cursor-plugin`, `.kimi-plugin`,
   `.opencode`, `.pi`, `gemini-extension.json`, `GEMINI.md`.
2. `git remote add upstream https://github.com/obra/superpowers` (add other upstreams as needed).
3. Confirm namespace `joe-bag-of-tricks` in `.claude-plugin/plugin.json`.
4. Create `@docs/customizations.md` and classify every already-modified file (see below).

## Per-Sync Procedure
1. `git fetch upstream --tags`; create branch `sync/upstream-vX.Y.Z`.
2. For each path with a non-empty `git diff <prev-tag>..<new-tag>`, act by its manifest state:
   - **vendored** — take upstream wholesale.
   - **patched** — diff-merge; hand-resolve only the overlapping lines.
   - **replaced** — DO NOT merge. Read the upstream diff, decide whether to port any idea into
     your version by hand, record the decision. You own the file; upstream is a feed of ideas.
3. New upstream files: classify and, before vendoring, verify license per `@docs/licensing.md`.
4. Update every touched row in `@docs/customizations.md` (state + source + license + reason(s)).
5. Merge as a real merge commit (NEVER squash a sync). Validate: `claude plugin validate`.

## Classifying a Modified File
- Diff concentrated in one block, additive → **patched**; consider lifting it to a sidecar file
  the SKILL.md references, so future merges stay clean.
- Diff smeared across the spine (checklist, process graph, inline commands) and divergence is
  substantial → **replaced**.
- "Why" may be a list, not one cause (e.g. `replaced: beads persistence + stricter model gate`).

## Red Flags
- NEVER assume a single concern (beads or otherwise) accounts for a file's full divergence.
- NEVER squash an upstream sync. NEVER auto-merge a `replaced` file.
- NEVER vendor a file whose license is unknown or incompatible.
