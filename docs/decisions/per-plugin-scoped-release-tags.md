# Per-Plugin Scoped Release Tags

## Decision

Tag plugin releases with a per-plugin scoped tag, `<plugin-name>-vX.Y.Z`, instead of a bare
`vX.Y.Z`:

- `joe-bag-of-tricks-v1.0.1`
- `joe-magic-bootstrap-v1.0.0`
- `joe-magic-design-v1.0.0`

Each plugin is tagged independently, at its own `plugin.json` version, on its own release
cadence. A change to one plugin's version does not require or imply a tag for the other.

The existing unscoped tags (`v0.1.0`, `v0.2.0`, `v0.3.0`, `v1.0.0`) predate `joe-magic-bootstrap`
and are left as historical artifacts — they are not retagged or migrated.

`joe-bag-of-tricks` continues to track upstream `superpowers` releases via its own tag lineage
(see `docs/upstream-sync.md`); this decision only changes the tag's name shape, not the sync
procedure. `joe-magic-bootstrap` and `joe-magic-design` have no upstream to track — they each
get an ordinary scoped tag whenever their `plugin.json` version bumps.

## Rationale

The marketplace now ships three independently-versioned plugins
(`plugins/joe-bag-of-tricks`, `plugins/joe-magic-bootstrap`, `plugins/joe-magic-design`), each
with its own `plugin.json` `version` field. A bare `vX.Y.Z` tag is ambiguous once multiple
plugins can be at different version numbers at the same point in repo history — a reader can't
tell which plugin's release the tag marks. Scoping the tag by plugin name removes the ambiguity
and matches the convention used by other multi-package repos (Go multi-module repos'
`<module-path>/vX.Y.Z`, npm monorepo tools like lerna/changesets): one version lineage per
shippable unit, one tag prefix per lineage.

## Choosing the Version

Semver applies to the plugin's behavior, not to its diff size. A skill is behavior: guidance an
agent will follow.

- **MINOR** — a skill gains new behavior: a new step, protocol, contract, or prohibition that
  changes what an agent does. Also a new skill or agent.
- **PATCH** — a fix to existing behavior: a wrong instruction, a broken cross-reference,
  frontmatter that fails validation, a typo.
- **MAJOR** — a skill or agent is removed or renamed, breaking references from outside the plugin.

"It's only a few lines of markdown" is not a PATCH argument. `1.2.0` shipped ~50 added lines and
was MINOR because those lines told controllers to escalate on new triggers — behavior that did
not exist at `1.1.1`.

## Tagging Under Squash-Merge

Feature branches squash-merge, so a branch that bumps the version more than once arrives on
`main` as a single commit carrying only the final version. Tag that squash commit, at the version
its `plugin.json` actually reads.

**Intermediate versions are never tagged.** They existed only inside the branch and were never a
state of `main`; a tag pointing at a tree whose manifest reads a different number asserts a
release that never shipped. Gaps in the tag sequence are expected and correct —
`joe-bag-of-tricks` has no `v1.1.0` tag for exactly this reason (PR #22 bumped 1.1.0 then 1.1.1
before merging). When a release covers skipped versions, say so in its release notes so the gap
does not read as an oversight.

Prefer a single bump per branch, set at the end, to avoid creating the gap at all.

## The "Latest" Badge

GitHub tracks one Latest release per repository, which cannot be accurate for three
independently-versioned plugins. Point it at the most recent release across all three
(`gh release create --latest`), and pass `--latest=false` when backfilling an older tag so it
does not steal the badge.
