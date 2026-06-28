# Customizations Manifest

Per-file record of how this fork diverges from upstream. **Read before any sync or before
editing an inherited file.** Source of truth for resolving sync conflicts.

States: `vendored` (take upstream wholesale) · `patched` (diff-merge; edits in place or in a
sidecar file) · `replaced` (yours wins; watch upstream and port by hand, never auto-merge).

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/brainstorming | replaced | obra/superpowers | MIT | beads work-decomposition woven through spine; revisit if upstream core proves stable |
| skills/subagent-driven-development | replaced | obra/superpowers | MIT | beads persistence across every node + model-selection additions |
| skills/writing-skills | patched | obra/superpowers | MIT | Anthropic skill-creator + best-practices fork (sidecar: anthropic-skill-creator.md) |
| AGENTS.md | replaced | obra/superpowers | MIT | upstream only points to CLAUDE.md; this carries the full beads workflow |

<!-- Add a row for every file the first-run init sweep classifies. Classify by git diff, not memory. -->
