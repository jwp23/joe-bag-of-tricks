# Converting Your Workflow into a Claude Code Plugin

A practical, prompt-driven guide for turning a pile of skills, agents, hooks,
commands, and MCP servers into a single installable plugin you can sync across
machines (and optionally share).

Audience: you already use Claude Code and have skills/agents in `.claude/`. You
want them packaged, versioned, and installable with one command everywhere you
work.

---

## Strategy in 60 seconds

You are building **one git repo that is both a marketplace and the plugin it
ships** (a "monorepo marketplace"). Add it once per machine; a git push from any
machine plus `/plugin marketplace update` propagates the change everywhere else.

Two facts decide almost every design choice — internalize them before you start:

1. **There is no per-component enable/disable inside a plugin.** A plugin is the
   atomic unit you install, enable, and disable. You cannot install a plugin and
   then keep 6 of its skills while turning 3 off.
2. **Plugin components are always namespaced.** A skill `foo` inside plugin
   `bar` is invoked `/bar:foo`, never `/foo`. Auto-triggering by description is
   unchanged, but explicit slash-invocation and any cross-references must use the
   namespaced form.

The practical consequence: **if your skills reference each other, ship them as
one plugin.** Splitting coupled skills across plugins doesn't give users
"mix-and-match" — it gives them broken cross-references and "install A, but A
needs B and C anyway." Real composability for coupled, opinionated skills is
*use-time* (skills auto-fire only when relevant), not install-time.

The whole job, top to bottom:

```
inventory → research the format → decide architecture → name it → choose versioning
→ scaffold + copy → fix broken references → genericize → wire hooks/MCP → license
→ validate → write the README → ship + sync
```

Most of these are short. The two that deserve real thought are **architecture**
(one plugin or several?) and **genericize** (what's a portable convention vs. a
project-specific assumption?).

---

## How to drive the agent (meta-lessons)

These are the lessons that make the difference between a clean conversion and a
broken one. Give them to the agent up front.

- **Make it research the format, not recall it.** The plugin/marketplace spec
  changes. Have the agent verify `plugin.json`/`marketplace.json` fields and the
  CLI against current docs (delegate to a subagent) instead of writing manifests
  from memory. A single wrong field name silently breaks install.
- **Force the architecture decisions *before* copying files.** Granularity,
  naming, and versioning determine the directory layout and every namespace
  prefix. Deciding them after you've copied 60 files means redoing the copy.
- **Work on copies; never edit the originals.** Copy `.claude/skills` etc. into
  the new repo first, then fix references on the copies. Your working setup keeps
  running while you build.
- **Delegate research and inventory to subagents.** Format research and
  reference-hunting produce a lot of tool output you don't need in your main
  context. Push them into subagents that return just the conclusion.
- **Don't invent provenance or licenses.** If a skill is adapted from someone
  else's work, find the real LICENSE and copyright line. Don't fabricate a URL or
  a notice.
- **Validate before you ship.** `claude plugin validate <path>` catches missing
  frontmatter, bad JSON, and manifest mismatches in seconds.

### Model and effort per phase

Delegate the mechanical and research-heavy phases; keep the judgment calls on the
most capable model at high effort.

| Phase | Run it | Model tier | Effort | Why |
|-------|--------|-----------|--------|-----|
| Research the format | Subagent | Sonnet / docs-guide agent | medium | Doc gathering; keep out of main context |
| Inventory | Inline | any | low | `ls` / `grep` |
| **Architecture decision** | Inline (you + agent) | **Opus** | **high–xhigh** | Judgment; sets the whole layout |
| Naming / versioning | Inline | Opus | high | Judgment, hard to change later |
| Scaffold + copy | Inline | Sonnet | low | Mechanical |
| Fix references | Inline | Opus / Sonnet | medium | Must spot what breaks when extracted |
| **Genericize** | Inline | **Opus** | **medium–high** | Judgment about project-specific vs portable |
| Wire hooks / MCP | Inline | Sonnet | medium | Config; verify the exact format |
| License / attribution | Inline | Opus | medium | Compliance; get it right |
| Validate | Inline | any | low | Run the validator |
| Write the README | Inline | Sonnet | low | Templated |
| Ship + sync | Inline | any | low | `git` / `gh` |

---

## The phases

Each phase below has a **copy-paste prompt**, what the agent should do, the
**decision** you own, and the **gotchas**.

### Phase 1 — Inventory

> **Prompt:**
> "List everything under my `.claude/` directory: every skill (with its
> `SKILL.md` description), every agent (name, model, tools), every command, every
> hook, and any MCP config. Then grep the skills and agents for references to
> project-specific things — file paths into this repo, tool names, issue-tracker
> commands, language/build commands — and give me the list of files that contain
> them. Don't change anything yet."

You want a clear picture of what you have and which pieces carry assumptions
before you decide how to package them.

### Phase 2 — Research the format (delegate)

> **Prompt (to a research/docs subagent):**
> "Research and report the current, authoritative Claude Code plugin and
> marketplace format — cite docs, don't guess. I need: (1) `plugin.json` required
> and optional fields and the `.claude-plugin/` layout; (2) exact locations and
> discovery rules for skills, agents, commands, hooks, and MCP servers inside a
> plugin; (3) the `marketplace.json` schema and how a plugin entry's `source`
> references a plugin in the *same* repo (relative path) vs. an external repo;
> (4) whether one repo can be both the marketplace and contain the plugin, and the
> canonical monorepo layout; (5) the exact CLI/slash commands to add a marketplace
> from git, install a plugin, and pull updates on other machines; (6) how updates
> propagate — version resolution (semver vs commit SHA); (7) gotchas: namespacing,
> reserved marketplace names, `${CLAUDE_PLUGIN_ROOT}`, and private-repo auth.
> Return copy-pasteable JSON and exact command syntax with citations."

Verified facts you should get back (current as of this writing — always re-verify):

- A plugin's manifest is `<plugin-root>/.claude-plugin/plugin.json`. **Required:**
  `name`, `description`. Common optional: `version`, `author`, `homepage`,
  `repository`, `license`.
- Components live at the **plugin root** (not inside `.claude-plugin/`) and are
  auto-discovered by convention: `skills/<name>/SKILL.md`, `agents/*.md`,
  `commands/*.md`, `hooks/hooks.json`, `.mcp.json`.
- A marketplace's manifest is `<repo-root>/.claude-plugin/marketplace.json` with
  `name`, `owner`, and a `plugins[]` array. A plugin in the same repo is
  referenced with a relative `source` like `"./plugins/my-plugin"` (relative
  paths only resolve when the marketplace is added via git).
- Reserved marketplace names impersonating Anthropic are rejected — pick your own.

### Phase 3 — Decide the architecture (one plugin or several?)

This is the decision that matters most. Run the **coupling test**.

> **Prompt:**
> "Here are my skills and agents: [paste the inventory]. Map the dependencies:
> which skills reference, dispatch, or chain into which other skills or agents?
> Then recommend whether this should be a single plugin or several, given two
> hard constraints: (a) Claude Code has no per-component enable/disable within a
> plugin, and (b) plugin components are always namespaced, so a skill in plugin A
> that references a bare skill name will break if that skill lives in plugin B.
> Flag every cross-reference that would break under a split. Default to a single
> plugin unless the groups are genuinely independent."

**The decision is yours.** Rule of thumb:

- **Coupled and/or opinionated** (skills call each other, share an issue tracker
  or workflow): **one plugin.** This is the common case.
- **Genuinely independent groups** (no cross-references, different problem
  domains): multiple plugins are fine and let users install subsets — at the cost
  of more manifests and more installs per machine.

Don't chase install-time mix-and-match for coupled skills. The system can't give
it to you, and faking it breaks references.

### Phase 4 — Name it

There are **three names**, and they don't have to differ:

- **Repo name** — used in `/plugin marketplace add owner/repo`.
- **Marketplace name** (`marketplace.json`) — used in
  `/plugin install plugin@marketplace`.
- **Plugin name** (`plugin.json`) — becomes the **slash prefix on every skill**
  (`/plugin-name:skill`).

> **Prompt:**
> "I want to name this plugin/marketplace. Show me how each candidate name reads
> in the three places it appears: the `marketplace add` command, the `install`
> command, and the slash prefix on a skill like `/NAME:systematic-debugging`.
> The plugin name is typed rarely (skills mostly auto-fire), so optimize the
> prefix for memorability over brevity. Avoid near-misses between the repo and
> plugin names — either match them exactly or make them clearly distinct."

Simplest choice: **make all three identical.** One name to remember everywhere.
A short, distinct plugin prefix is worth it only if you invoke skills by slash a
lot.

### Phase 5 — Choose versioning

Two strategies:

- **Explicit semver** (recommended for a shared/stable plugin): set `version` in
  `plugin.json`, bump it on every change you want to propagate. Predictable;
  others can pin. *You must remember to bump* or updates won't show.
- **Git commit = version** (simplest for a purely personal, fast-moving plugin):
  omit `version`; every pushed commit is a new version. No bumps to remember.

> **Prompt:**
> "Set up [explicit semver | git-SHA] versioning for this plugin and add a one-
> line reminder in the README explaining how a change propagates to my other
> machines under that scheme."

### Phase 6 — Scaffold and copy

> **Prompt:**
> "Create the repo at [path] with this monorepo-marketplace layout: a
> `.claude-plugin/marketplace.json` at the root, and the plugin under
> `plugins/<name>/` with its own `.claude-plugin/plugin.json`, plus `skills/`,
> `agents/`, `commands/`, `hooks/` as applicable. Copy my skills, agents, and
> commands from `.claude/` into the plugin, preserving every supporting file
> (scripts, examples, prompt templates, reference docs). Copy the originals —
> don't move them. Then write both manifests from the researched schema."

Reference layout:

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

### Phase 7 — Fix broken cross-references

Extracting skills from your repo breaks anything that pointed *into* that repo.

> **Prompt:**
> "Search the copied skills and agents for references that break now that
> they're extracted from the original repo: hard-coded paths into the old repo
> (`.claude/...`, `docs/...`), dispatches to agents by old file path, and any file
> a skill points at that didn't come along. Report each as `file:line` with a
> proposed fix. Two rules: agent dispatches must use the namespaced form
> `plugin-name:agent-name` (not a file path), and any design docs a skill cites
> must either be carried into the plugin or the reference removed. Apply fixes to
> the copies only."

Common breakages:

- A skill that dispatches an agent by path (`.claude/agents/foo.md`) → change to
  the namespaced agent name `my-plugin:foo`.
- A skill citing a doc in the old repo → carry the doc into the plugin (e.g. a
  `docs/` folder inside the plugin) or drop the citation.

### Phase 8 — Genericize project-specific assumptions

Decide, per assumption, whether it's a **portable convention** you want
everywhere or a **project-specific detail** that should be parameterized or
removed.

> **Prompt:**
> "Search the copied content for assumptions tied to specific projects:
> hard-coded language/build/test commands (e.g. `cargo test`, `npm test`),
> issue-tracker commands, decision-doc paths, framework names. For each, classify
> it as: KEEP (a convention I want in every project), PARAMETERIZE (make it
> language/tool-neutral with the specific as just an example), or REMOVE (it only
> made sense in the origin project). Show me the table and your recommendation
> before changing anything."

You own the KEEP/PARAMETERIZE/REMOVE calls. Typical outcome: keep your
cross-project conventions (issue tracker, decision-doc format), parameterize
language/build commands to neutral phrasing, and remove anything that only fit
the origin project. Drop origin-specific commands entirely rather than shipping
them generically half-broken.

### Phase 9 — Wire hooks and MCP servers (skip if you have none)

**Hooks** live in `<plugin-root>/hooks/hooks.json` (auto-discovered) or inline in
`plugin.json` under a `hooks` key. Reference bundled scripts with
`${CLAUDE_PLUGIN_ROOT}`.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-bash.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**MCP servers** live in `<plugin-root>/.mcp.json` (auto-loaded when the plugin is
enabled) or inline in `plugin.json` under `mcpServers`. Reference bundled files
with `${CLAUDE_PLUGIN_ROOT}`.

```json
{
  "mcpServers": {
    "my-server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

> **Prompt:**
> "I have these hooks / MCP servers in my personal config: [paste]. Move them into
> the plugin: hooks into `hooks/hooks.json`, MCP servers into `.mcp.json` at the
> plugin root. Rewrite every path that pointed at my home directory or the old
> repo to use `${CLAUDE_PLUGIN_ROOT}`, and copy the referenced scripts into the
> plugin. Confirm they auto-discover when the plugin is enabled."

Path placeholders available: `${CLAUDE_PLUGIN_ROOT}` (plugin install dir),
`${CLAUDE_PLUGIN_DATA}` (persists across updates), `${CLAUDE_PROJECT_DIR}`
(project root).

### Phase 10 — License and attribution

If any component is adapted from someone else's work, comply with their license.

> **Prompt:**
> "Some of these skills are adapted from [source project]. Find that project's
> LICENSE and its exact copyright line — don't guess it. Tell me what the license
> requires for redistribution. Then write a LICENSE for my repo that complies
> (preserve their notice), add a `license` field to `plugin.json`, and add an
> accurate attribution section to the README listing which components are derived
> vs. original. If I plan to publish, flag anything I must resolve first."

Attribution matters most before **public** distribution. For a private,
personal repo you still comply, but there's no external audience yet.

### Phase 11 — Validate

> **Prompt:**
> "Run `claude plugin validate` on both the marketplace root and the plugin
> directory. Fix every error and every warning — including missing command/agent
> frontmatter — and re-run until both pass clean. Also confirm the JSON in both
> manifests parses."

```bash
claude plugin validate .                       # marketplace
claude plugin validate ./plugins/my-plugin     # plugin
```

### Phase 12 — Write the README (install instructions)

The install instructions **differ for public vs. private repos**, so the prompt
must ask first.

> **Prompt:**
> "Write the install and cross-machine sync section of the README. First ask me:
> is this repo public or private? Then produce the correct instructions.
> - If **public**: `/plugin marketplace add owner/repo` then
>   `/plugin install plugin@marketplace`.
> - If **private**: lead with the SSH URL form
>   `/plugin marketplace add git@github.com:owner/repo.git` as most reliable; note
>   the `owner/repo` shorthand also works when a git credential helper is
>   configured (`gh auth setup-git`); and note that background auto-update runs
>   without credential helpers, so it needs a `GITHUB_TOKEN` (or `GH_TOKEN`) with
>   read access exported in the shell profile.
> For both: state that plugins install at user scope (available in every
> project), that skills auto-trigger by description and can be invoked explicitly
> as `/plugin:skill`, and document the sync flow — bump the version (or push a
> commit under git-SHA versioning), push, then run
> `/plugin marketplace update <marketplace>` on the other machine."

**Public install:**

```text
/plugin marketplace add owner/repo
/plugin install my-plugin@my-marketplace
```

**Private install** (SSH is most reliable):

```text
/plugin marketplace add git@github.com:owner/repo.git
/plugin install my-plugin@my-marketplace
```

For private repos, `ssh-agent` must have your key loaded and `github.com` must be
in `~/.ssh/known_hosts`. For **automatic** startup updates of a private
marketplace, export a token (manual `/plugin marketplace update` uses your
interactive git credentials and needs no token):

```bash
export GITHUB_TOKEN=…   # read access to the private repo, in your shell profile
```

### Phase 13 — Ship and sync

> **Prompt:**
> "Initialize git, make a clean initial commit, and create the [public | private]
> GitHub repo and push. Then give me the exact add + install commands for this
> machine and for a second machine, and the version-bump + update flow for
> propagating future changes."

```bash
# create + push (private example)
gh repo create my-marketplace --private --source=. --remote=origin --push

# propagate a change from any machine:
#   1) edit, 2) bump version in plugin.json, 3) git commit && git push
# on every other machine:
#   /plugin marketplace update my-marketplace
```

For local development before pushing:

```text
/plugin marketplace add /absolute/path/to/my-marketplace
/plugin install my-plugin@my-marketplace
/plugin validate /absolute/path/to/my-marketplace
```

Use `/reload-plugins` to pick up local edits without restarting.

---

## Gotchas

| Gotcha | What happens | Fix |
|--------|--------------|-----|
| No per-component toggle | You can't keep some skills of a plugin and disable others | Package coupled skills as one plugin; split only truly independent groups |
| Namespacing is mandatory | `/skill` becomes `/plugin:skill`; bare cross-references break | Update in-plugin references to the namespaced form |
| Relative `source` needs git | `"./plugins/x"` fails if the marketplace is added by raw URL | Add the marketplace via GitHub shorthand or a git URL |
| Version didn't change | Other machines keep the cached copy, no update | Bump `version` (semver) or push a new commit (git-SHA scheme) |
| Reserved marketplace names | Names impersonating Anthropic are rejected | Pick your own name |
| Private repo, no token | Background auto-update can't authenticate at startup | Export `GITHUB_TOKEN`/`GH_TOKEN` with read access |
| Command/agent missing frontmatter | Validator warns; no description in the UI | Add YAML frontmatter with at least a `description` |
| Broken paths after extraction | Skills cite files that stayed in the old repo | Carry the file into the plugin or drop the reference |
| Editing originals in place | You destabilize your working setup mid-build | Always work on copies |
| Duplicate skills after install | Project-level `.claude/skills` + the plugin both active → two near-identical entries | Remove the now-duplicated project-level copies after cutover |

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
> evolves — when in doubt, have the agent re-verify against current docs (Phase 2)
> rather than trusting this page.
