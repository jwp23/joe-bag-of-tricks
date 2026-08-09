# Architecture — Repo & Plugin Layout

**Read when unsure where a component belongs.** Two splits drive every placement call: marketplace
root vs plugin root, and shipped (plugin) vs authoring-only (`.claude/` + repo-root `docs/`). The
authoring split is the highest-risk gotcha.

## Marketplace, then plugins
This repo is a Claude Code **marketplace** that ships TWO nested plugins, `joe-bag-of-tricks` and
`joe-magic-bootstrap`:
- `.claude-plugin/marketplace.json` (repo root) — the **marketplace** manifest. Each plugin entry's
  `source` (`./plugins/joe-bag-of-tricks`, `./plugins/joe-magic-bootstrap`) points at that plugin's root.
- `plugins/joe-bag-of-tricks/` and `plugins/joe-magic-bootstrap/` — **plugin roots**. "At the plugin
  root" below means *one of these*, not the repo root; each plugin has its own.

There are therefore THREE `.claude-plugin/` dirs — don't conflate them:
- `.claude-plugin/marketplace.json` at the repo root.
- `plugins/joe-bag-of-tricks/.claude-plugin/plugin.json` at the `joe-bag-of-tricks` plugin root.
- `plugins/joe-magic-bootstrap/.claude-plugin/plugin.json` at the `joe-magic-bootstrap` plugin root.

This nesting matters for upstream-sync (which only applies to `joe-bag-of-tricks`, the only plugin
with an upstream): an upstream path `<p>` maps to `plugins/joe-bag-of-tricks/<p>`.

## Shipped in a plugin (component dirs at that plugin's root)
Under `plugins/joe-bag-of-tricks/`:
- `skills/<name>/SKILL.md` — workflow skills (inherited + custom), namespaced `/joe-bag-of-tricks:<name>`.
- `agents/<name>.md` — custom subagents.
- `hooks/` — `hooks.json` + `session-start`: a Claude-only SessionStart hook that injects the
  `using-skills` skill at session start (auto-discovered via `hooks/hooks.json`; adapted from upstream).
- `.claude-plugin/plugin.json` — the plugin manifest. The ONLY file inside *that* `.claude-plugin/`.

Under `plugins/joe-magic-bootstrap/`:
- `skills/project/SKILL.md` — the one skill this plugin ships, namespaced `/joe-magic-bootstrap:project`.
- `.claude-plugin/plugin.json` — its own plugin manifest, same rule as above.

The same component-dir and manifest-placement rules apply to both plugin roots; the rest of this
doc uses `joe-bag-of-tricks` as the running example unless a rule is specific to
`joe-magic-bootstrap`.

## NOT shipped (authoring-only, at the repo root)
- `.claude/skills/upstream-sync/` — maintains the fork; never distributed.
- `.claude/rules/*.md` — team rules loaded alongside CLAUDE.md.
- `.claude/settings.json` — permission allowlist.
- `docs/` (repo root) — fork-maintenance docs: customizations, upstream-sync, licensing, architecture,
  the hands-on-keyboard workflow guide, and all ADRs (`docs/adr/`). Not shipped — not installed by
  `/plugin install`, but not maintainer-only either: `workflow-guide.md` is written for whoever is
  using the toolkit, day to day.

## ADR placement
All ADRs live in repo-root `docs/adr/`, one global number sequence covering both plugins. They are
maintainer rationale and do not ship with either plugin (`plugins/joe-bag-of-tricks/` or
`plugins/joe-magic-bootstrap/`) — this holds whether the decision concerns a shipped component
(ADR-001) or the authoring workflow (ADR-002).

## Hard rules
- Component dirs NEVER go inside `.claude-plugin/`. Only the manifest lives there.
- Authoring tooling NEVER ships in the plugin — keep it under repo-root `.claude/`, and authoring
  docs under repo-root `docs/`.
- A subagent needing `hooks`, `mcpServers`, or `permissionMode` frontmatter must live in
  `.claude/agents/` and be installed directly — plugin-distributed agents ignore those fields.
