# Architecture — Repo & Plugin Layout

**Read when unsure where a component belongs.** Two splits drive every placement call: marketplace
root vs plugin root, and shipped (plugin) vs authoring-only (`.claude/` + repo-root `docs/`). The
authoring split is the highest-risk gotcha.

## Marketplace, then plugin
This repo is a Claude Code **marketplace** that ships ONE nested plugin:
- `.claude-plugin/marketplace.json` (repo root) — the **marketplace** manifest. Its plugin entry's
  `source: "./plugins/joe-bag-of-tricks"` points at the plugin root.
- `plugins/joe-bag-of-tricks/` — the **plugin root**. "At the plugin root" below means *here*, not
  the repo root.

There are therefore TWO `.claude-plugin/` dirs — don't conflate them:
- `.claude-plugin/marketplace.json` at the repo root.
- `plugins/joe-bag-of-tricks/.claude-plugin/plugin.json` at the plugin root.

This nesting matters for upstream-sync: an upstream path `<p>` maps to `plugins/joe-bag-of-tricks/<p>`.

## Shipped in the plugin (component dirs at the plugin root)
Under `plugins/joe-bag-of-tricks/`:
- `skills/<name>/SKILL.md` — workflow skills (inherited + custom), namespaced `/joe-bag-of-tricks:<name>`.
- `agents/<name>.md` — custom subagents.
- `hooks/` — shell + Node hooks (inherited).
- `.claude-plugin/plugin.json` — the plugin manifest. The ONLY file inside *that* `.claude-plugin/`.

## NOT shipped (authoring-only, at the repo root)
- `.claude/skills/upstream-sync/` — maintains the fork; never distributed.
- `.claude/rules/*.md` — team rules loaded alongside CLAUDE.md.
- `.claude/settings.json` — permission allowlist.
- `docs/` (repo root) — fork-maintenance docs: customizations, upstream-sync, licensing, architecture,
  and all ADRs (`docs/adr/`). Maintainer-facing; not shipped.

## ADR placement
All ADRs live in repo-root `docs/adr/`, one global number sequence. They are maintainer rationale
and do not ship with the plugin (`plugins/joe-bag-of-tricks/` only) — this holds whether the decision
concerns a shipped component (ADR-001) or the authoring workflow (ADR-002).

## Hard rules
- Component dirs NEVER go inside `.claude-plugin/`. Only the manifest lives there.
- Authoring tooling NEVER ships in the plugin — keep it under repo-root `.claude/`, and authoring
  docs under repo-root `docs/`.
- A subagent needing `hooks`, `mcpServers`, or `permissionMode` frontmatter must live in
  `.claude/agents/` and be installed directly — plugin-distributed agents ignore those fields.
