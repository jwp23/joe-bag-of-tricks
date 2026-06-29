# Customizations Manifest

Per-file record of how this fork diverges from upstream. **Read before any sync or before
editing an inherited file.** Source of truth for resolving sync deltas.

**Last synced:** `obra/superpowers` @ `8ea3981` (initial fork point). The next sync diffs
`8ea3981...<head>` via `gh api repos/obra/superpowers/compare/8ea3981...<head>`; update this to the
head ref after each sync — it is the anchor that keeps the next diff small (see
`adr/002-no-remote-upstream-sync.md`).

Paths are **fork paths**. Plugin payload is nested under `plugins/joe-bag-of-tricks/`; repo-level
files (CLAUDE.md, AGENTS.md, …) stay at the repo root.

States: `vendored` (take upstream wholesale) · `patched` (reconcile by hand; edits in place or in a
sidecar file) · `replaced` (yours wins; read upstream for ideas and port by hand, never apply).

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| plugins/joe-bag-of-tricks/skills/brainstorming | replaced | obra/superpowers | MIT | beads work-decomposition woven through spine; revisit if upstream core proves stable |
| plugins/joe-bag-of-tricks/skills/subagent-driven-development | replaced | obra/superpowers | MIT | beads persistence across every node + model-selection additions |
| plugins/joe-bag-of-tricks/skills/writing-skills | patched | obra/superpowers | MIT | Anthropic skill-creator + best-practices fork (sidecar: anthropic-skill-creator.md) |
| AGENTS.md | replaced | obra/superpowers | MIT | upstream only points to CLAUDE.md; this carries the full beads workflow |

<!-- Add a row for every file a sync touches. Classify by the upstream diff, not memory. -->
