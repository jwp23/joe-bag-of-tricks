# Architecture — Plugin Layout

**Read when unsure where a component belongs.** The root-vs-`.claude/` split is the highest-risk
gotcha in this repo.

## Shipped in the plugin (component dirs at the ROOT)
- `skills/<name>/SKILL.md` — workflow skills (inherited + custom), namespaced `/joe-bag-of-tricks:<name>`.
- `agents/<name>.md` — custom subagents.
- `hooks/` — shell + Node hooks (inherited).
- `.claude-plugin/plugin.json` — the manifest. The ONLY file inside `.claude-plugin/`.

## NOT shipped (authoring-only, in `.claude/`)
- `.claude/skills/upstream-sync/` — maintains the fork; never distributed.
- `.claude/rules/*.md` — team rules loaded alongside CLAUDE.md.
- `.claude/settings.json` — permission allowlist.

## Hard rules
- Component dirs NEVER go inside `.claude-plugin/`. Only `plugin.json` lives there.
- Authoring tooling NEVER ships in the plugin — keep it in `.claude/`.
- A subagent needing `hooks`, `mcpServers`, or `permissionMode` frontmatter must live in
  `.claude/agents/` and be installed directly — plugin-distributed agents ignore those fields.
