# Upstream Sync Rules
Syncing a new upstream release, or editing any inherited file? YOU MUST invoke the
`/upstream-sync` skill (authoring-only; not shipped) — it owns the no-remote tag-diff (GitHub
compare), diff-driven classification, and hand-porting by manifest state.
IMPORTANT: Classify every touched file in `@docs/customizations.md` by the upstream diff, not by
memory — a file may diverge for more than one reason. Never apply an upstream change into a
`replaced` file.
