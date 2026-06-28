# Upstream Sync Rules
Syncing a new upstream release, or editing any inherited file? YOU MUST invoke the
`/upstream-sync` skill (authoring-only; not shipped) — it owns the tag-merge, diff-driven
classification, and conflict resolution.
IMPORTANT: Classify every modified file in `@docs/customizations.md` by its git diff, not by
memory — a file may diverge for more than one reason. Never auto-merge a `replaced` file.
