# Converting Your Workflow into a Claude Code Plugin

A prompt-driven guide for turning a pile of skills, agents, hooks, commands, and
MCP servers into a single installable plugin you can sync across machines (and
optionally share).

Audience: you already use Claude Code and keep skills/agents in `.claude/`. You
want them packaged, versioned, and installable with one command everywhere you
work.

---

## The fast path — two prompts

The whole job collapses to **two prompts in one session**: a *plan* prompt that
interviews you and stops for approval, then an *execute* prompt that builds and
ships. Run both on your most capable model at high/xhigh effort — there’s no
model switching, so there’s no reason to break it up further.

**Minimal entry** — if you remember nothing else, paste this:

> "Convert my `.claude` at `<path>` into a plugin — interview me for the rest,
> then show me a plan before touching any files."

The interview fills in everything below.

### Prompt 1 — Plan (interviews for anything you leave blank)

```
I want to convert my Claude Code customizations into a single installable plugin,
distributed via a git-backed monorepo marketplace, that I can sync across machines.

Here's what I've decided (leave blank what you don't know):
- Source path (.claude dir): <...>
- Name (repo = marketplace = plugin): <...>
- Visibility + owner: <...>
- Versioning: <...>
- Genericize policy (conventions to KEEP everywhere): <...>
- Attribution (adapted from anything? which project): <...>

For anything I left blank, INTERVIEW me — one topic at a time, recommend a default,
and wait for my answer. Don't guess my name or my conventions.

Then, before touching any files:
1. Verify the CURRENT plugin/marketplace format against the docs (don't recall from memory).
2. Inventory my customizations; grep for project-specific references.
3. Run the coupling test — map which skills/agents reference each other — and
   recommend ONE plugin unless groups are genuinely independent.
4. Present a PLAN for approval: architecture (one plugin vs split, with the coupling
   evidence), the resolved name / visibility / versioning, and a KEEP / PARAMETERIZE /
   REMOVE table for every project-specific reference you found.

Stop there. Change nothing until I approve.
```

### Prompt 2 — Execute (after you approve the plan)

```
Approved — build it end-to-end in this session:
1. Scaffold the monorepo layout; COPY (never move) everything in, preserving supporting files.
2. Fix every reference that breaks once extracted (agent dispatches → namespaced
   name:agent; cited docs → carry in or drop).
3. Genericize per the approved KEEP / PARAMETERIZE / REMOVE table.
4. Wire hooks → hooks/hooks.json and MCP → .mcp.json; rewrite bundled paths to ${CLAUDE_PLUGIN_ROOT}.
5. Handle license/attribution as agreed.
6. Run `claude plugin validate` on the marketplace and the plugin; fix all errors and warnings.
7. Write the README (install for public or private + the version-bump + `/plugin marketplace update` sync flow).
8. Ship: init git, clean commit, create the repo (public or private, as agreed), push —
   show me the file list before the first push. Then give me the add + install commands
   for this and other machines.

Guardrails: work on copies, never my originals; never invent field names, licenses,
URLs, or provenance — verify or ask.
```

**Why two, not one:** the only genuinely risky call is the plan — a wrong
*architecture* or *genericize* decision is expensive to unwind because everything
downstream (namespaces, layout, every edited file) is built on it. Prompt 1’s
stop-for-approval is a cheap checkpoint at exactly that seam. Everything else is
safe to run autonomously.

---

## The two facts that decide everything

Internalize these — they’re why the plan defaults to “one plugin,” and why the
agent must namespace references.

1. **There is no per-component enable/disable inside a plugin.** A plugin is the
   atomic unit you install, enable, and disable. You can’t keep 6 of its skills
   while turning 3 off.
2. **Plugin components are always namespaced.** A skill `foo` inside plugin `bar`
   is invoked `/bar:foo`, never `/foo`. Auto-triggering by description is
   unchanged, but explicit invocation and every cross-reference must use the
   namespaced form.

**Consequence:** if your skills reference each other, ship them as one plugin.
Splitting coupled skills across plugins doesn’t give mix-and-match — it gives
broken cross-references. Real composability for coupled skills is *use-time*
(skills auto-fire only when relevant), not install-time.

You are building **one git repo that is both a marketplace and the plugin it
ships** — a “monorepo marketplace.” Add it once per machine; a git push plus
`/plugin marketplace update` propagates the change everywhere else.

---

## Principles (bake these into any run)

- **Research, don’t recall.** The plugin/marketplace spec changes. Have the agent
  verify manifest fields and the CLI against current docs — a single wrong field
  name silently breaks install.
- **Work on copies.** Copy `.claude/` into the new repo first; never edit the
  originals. Your working setup keeps running while you build.
- **Don’t invent provenance or licenses.** If a skill is adapted from someone
  else’s work, find the real LICENSE and copyright line.
- **Validate before you ship.** `claude plugin validate <path>` catches missing
  frontmatter, bad JSON, and manifest mismatches in seconds.

---

## Reference — the 13 phases, condensed

What Prompt 1 and Prompt 2 are actually doing, step by step. Reach for this when a
step in the plan needs unpacking.

1. **Inventory** — List every skill/agent/command/hook/MCP and grep for
   project-specific references, so you know what you have and what carries assumptions.
2. **Research the format** — Verify the current plugin/marketplace schema and CLI
   against the docs; never write manifests from memory.
3. **Architecture** — Coupling test: map which skills/agents reference each other.
   Default to one plugin; a split only makes sense for genuinely independent groups.
4. **Name it** — Repo, marketplace, and plugin names; the plugin name becomes the
   `/prefix:` on every skill. Simplest: make all three identical.
5. **Versioning** — Explicit semver (bump to propagate) or git-SHA (every commit is
   a version). Semver for a shared/stable plugin.
6. **Scaffold + copy** — Build the monorepo layout; copy (never move) everything in,
   preserving every supporting file.
7. **Fix references** — Repoint what broke on extraction: agent dispatches →
   namespaced `name:agent`; docs a skill cites → carry into the plugin or drop.
8. **Genericize** — Per assumption: KEEP a portable convention, PARAMETERIZE a
   language/build command to neutral phrasing, or REMOVE origin-only detail.
9. **Hooks & MCP** — Hooks → `hooks/hooks.json`, MCP → `.mcp.json`; rewrite bundled
   paths to `${CLAUDE_PLUGIN_ROOT}`.
10. **License** — If adapted from someone’s work, find their real LICENSE and comply
    (preserve their notice); add a `license` field and README attribution.
11. **Validate** — `claude plugin validate` on the marketplace and the plugin; fix
    every error and warning.
12. **README** — Install instructions differ for public vs. private; document the
    version-bump + `/plugin marketplace update` sync flow.
13. **Ship** — git init, clean commit, create the repo, push; then hand back the
    add + install commands for every machine.

---

## Gotchas

| Gotcha | What happens | Fix |
|--------|--------------|-----|
| No per-component toggle | You can’t keep some skills of a plugin and disable others | Package coupled skills as one plugin; split only truly independent groups |
| Namespacing is mandatory | `/skill` becomes `/plugin:skill`; bare cross-references break | Update in-plugin references to the namespaced form |
| Relative `source` needs git | `"./plugins/x"` fails if the marketplace is added by raw URL | Add the marketplace via GitHub shorthand or a git URL |
| Version didn’t change | Other machines keep the cached copy, no update | Bump `version` (semver) or push a new commit (git-SHA scheme) |
| Reserved marketplace names | Names impersonating Anthropic are rejected | Pick your own name |
| Private repo, no token | Background auto-update can’t authenticate at startup | Export `GITHUB_TOKEN`/`GH_TOKEN` with read access |
| Command/agent missing frontmatter | Validator warns; no description in the UI | Add YAML frontmatter with at least a `description` |
| Broken paths after extraction | Skills cite files that stayed in the old repo | Carry the file into the plugin or drop the reference |
| Editing originals in place | You destabilize your working setup mid-build | Always work on copies |
| Duplicate skills after install | Project-level `.claude/skills` + the plugin both active → two near-identical entries | Remove the duplicated project-level copies after cutover |

---

## Appendix — templates and cheat-sheet

### `marketplace.json`

```json
{
  "name": "my-marketplace",
  "owner": { "name": "Your Name", "email": "you@example.com" },
  "description": "My personal Claude Code plugins.",
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "What this plugin does."
    }
  ]
}
```

### `plugin.json`

```json
{
  "name": "my-plugin",
  "description": "What this plugin does.",
  "version": "0.1.0",
  "author": { "name": "Your Name", "email": "you@example.com" },
  "homepage": "https://github.com/owner/repo",
  "repository": "https://github.com/owner/repo",
  "license": "MIT"
}
```

Optional `plugin.json` keys for non-default component locations (all paths
relative, starting with `./`): `skills` (adds to the default `skills/` scan),
`commands`, `agents`, `workflows`, `outputStyles` (each *replaces* its default),
`hooks`, `mcpServers`, `lspServers` (merge with defaults), plus `dependencies`
(other plugins this one requires) and `userConfig` (values prompted at enable
time). You rarely need any of these — the default locations are auto-discovered.

### Reference layout

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # the catalog
├── LICENSE
├── README.md
└── plugins/
    └── my-plugin/
        ├── .claude-plugin/
        │   └── plugin.json       # the plugin manifest
        ├── skills/               # skills/<name>/SKILL.md
        ├── agents/               # *.md with frontmatter
        ├── commands/             # *.md with frontmatter
        ├── hooks/                # hooks.json (if any)
        └── .mcp.json             # bundled MCP servers (if any)
```

### CLI / slash cheat-sheet

| Task | Command |
|------|---------|
| Add marketplace (public) | `/plugin marketplace add owner/repo` |
| Add marketplace (private, SSH) | `/plugin marketplace add git@github.com:owner/repo.git` |
| Add marketplace (local dev) | `/plugin marketplace add /abs/path` |
| Install plugin | `/plugin install plugin@marketplace` |
| List marketplaces / plugins | `/plugin marketplace list` · `/plugin list` |
| Pull latest (sync) | `/plugin marketplace update <marketplace>` |
| Validate | `claude plugin validate <path>` |
| Reload after local edits | `/reload-plugins` |
| Enable / disable a plugin | `/plugin enable <plugin>` · `/plugin disable <plugin>` |

> Facts here reflect the Claude Code plugin system at time of writing. The format
> evolves — when in doubt, have the agent re-verify against current docs (Prompt 1,
> step 1) rather than trusting this page.
