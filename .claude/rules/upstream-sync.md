# Upstream Sync Rules
Syncing a new upstream release, or editing any inherited file? YOU MUST invoke the
`/upstream-sync` skill (authoring-only; not shipped) — it owns the no-remote tag-diff (GitHub
compare), diff-driven classification, and hand-porting by manifest state.
IMPORTANT: Classify every touched file in `@docs/customizations.md` by the upstream diff, not by
memory — a file may diverge for more than one reason. Never apply an upstream change into a
`replaced` file.

WORDING POLICY (adopt-by-default): take upstream's wording by default, platform-neutralizations
included (`Task()`→`Subagent`, `Claude`→`agents`, `@import`→markdown-link, etc.). Keep a
Claude-specific term ONLY when Joe wants it (e.g. the "Circle K" signal) or it has a *verified*
Claude-Code functional effect. This is *not* "skip neutralization" — the default is adopt. Full
rationale + the standing exceptions are in `@docs/customizations.md` (overarching sync policy).
