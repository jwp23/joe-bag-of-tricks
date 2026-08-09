# Per-Plugin Scoped Release Tags

## Decision

Tag plugin releases with a per-plugin scoped tag, `<plugin-name>-vX.Y.Z`, instead of a bare
`vX.Y.Z`:

- `joe-bag-of-tricks-v1.0.1`
- `joe-magic-bootstrap-v1.0.0`

Each plugin is tagged independently, at its own `plugin.json` version, on its own release
cadence. A change to one plugin's version does not require or imply a tag for the other.

The existing unscoped tags (`v0.1.0`, `v0.2.0`, `v0.3.0`, `v1.0.0`) predate `joe-magic-bootstrap`
and are left as historical artifacts — they are not retagged or migrated.

`joe-bag-of-tricks` continues to track upstream `superpowers` releases via its own tag lineage
(see `docs/upstream-sync.md`); this decision only changes the tag's name shape, not the sync
procedure. `joe-magic-bootstrap` has no upstream to track — it just gets an ordinary scoped tag
whenever its `plugin.json` version bumps.

## Rationale

The marketplace now ships two independently-versioned plugins
(`plugins/joe-bag-of-tricks`, `plugins/joe-magic-bootstrap`), each with its own `plugin.json`
`version` field. A bare `vX.Y.Z` tag is ambiguous once two plugins can be at different version
numbers at the same point in repo history — a reader can't tell which plugin's release the tag
marks. Scoping the tag by plugin name removes the ambiguity and matches the convention used by
other multi-package repos (Go multi-module repos' `<module-path>/vX.Y.Z`, npm monorepo tools
like lerna/changesets): one version lineage per shippable unit, one tag prefix per lineage.
