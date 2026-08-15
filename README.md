# joe-bag-of-tricks

Personal [Claude Code](https://code.claude.com) plugins — a curated bag of engineering-workflow **skills** and **agents** that travel with Joe across every machine and project.

This repository is a plugin marketplace shipping two plugins. Add the marketplace once on each machine, install the plugin(s) you want, and keep them in sync through git.

**New to the workflow?** [`docs/workflow-guide.md`](docs/workflow-guide.md) is a hands-on-keyboard
walkthrough — what you type, start to finish, from an idea through a merged PR.

## What's inside

Two plugins.

`joe-bag-of-tricks` — the engineering workflow toolkit, bundling:

**Skills** (`skills/`)

| Skill | Use it when… |
|-------|--------------|
| `test-driven-development` | Implementing any feature or bugfix — write the failing test first |
| `systematic-debugging` | Investigating why something is broken, slow, or surprising |
| `verification-before-completion` | About to claim work is done, fixed, or passing |
| `using-skills` | Starting a conversation — discover and invoke relevant skills |
| `brainstorming` | Starting creative/design work before implementation |
| `writing-plans` | Turning a spec into a bd (beads) issue hierarchy |
| `executing-plans` | Executing a bd task hierarchy with review checkpoints |
| `subagent-driven-development` | Executing independent tasks via dispatched implementer subagents |
| `dispatching-parallel-agents` | Facing 2+ independent tasks with no shared state |
| `using-git-worktrees` | Isolating feature work from the current workspace |
| `requesting-code-review` | Verifying work meets requirements before merge |
| `receiving-code-review` | Evaluating review feedback before acting on it |
| `security-review` | Auditing changes for vulnerabilities before a PR |
| `finishing-a-development-branch` | Push → PR → CI → CodeRabbit → cleanup |
| `record-decision` | Capturing a technical decision (ADR or decision doc) |
| `readme-sync` | Keeping docs in sync after user-facing changes |
| `writing-skills` | Creating, editing, or verifying skills |
| `writing-agents` | Creating or editing subagents |
| `scripted-browser-verification` | Verifying a web UI — one Playwright script, compact output, never interactive browser calls |
| `ux-audit` | Auditing a finished UI batch for truncation, crowding, cryptic labels, and weak hierarchy |
| `implementer-contract` | Not invoked directly — the shared operating contract preloaded into the implementer agents |

**Agents** (`agents/`)

| Agent | Model | Effort | Role |
|-------|-------|--------|------|
| `coderabbit-reviewer` | sonnet | low | Evaluates and applies/rejects CodeRabbit PR comments |
| `pr-merger` | haiku | low | Squash-merges, verifies post-merge CI when the repo has Actions runs, cleans up |
| `branch-shepherd` | sonnet | medium | Delivers one or more review-clean branches end to end: push, PR, CI, CodeRabbit, conflict reconciliation, squash-merge, cleanup |
| `implementer-mechanical` | haiku | low | Executes a single, fully-specified SDD task — transcription-grade work where the plan already contains the code to write |
| `implementer` | sonnet | medium | Implements a single SDD task — the default tier for ordinary multi-file integration work |
| `implementer-complex` | opus | high | Implements an SDD task that needs design judgment or broad context; also the fix-loop escalation target |
| `adjudicator` | fable | high | Rules on one escalated question from an orchestrator — contradictory reports, a governing-decision conflict, an exhausted fix loop, a Critical finding — and edits nothing |

`joe-magic-bootstrap` — interactively generates a project's CLAUDE.md + `.claude/` structure (one skill, `project`).

## Workflow assumptions

These skills encode `joe-bag-of-tricks`' opinionated workflow. They assume:

- **beads (`bd`)** for issue tracking — planning and execution skills create/claim/close `bd` issues.
- **ADRs in `docs/adr/`** and decision docs in `docs/decisions/` for recording decisions.
- **`gh` CLI + a PR-based GitHub workflow** — feature branches, CI gates, squash merges.
- **TDD by default** and root-cause debugging.

They are language-agnostic where it matters (test/build commands are detected per project), so they work on non-Rust projects.

## Repository layout

```
joe-bag-of-tricks/
├── .claude-plugin/
│   └── marketplace.json          # marketplace catalog
├── docs/
│   └── adr/                      # architecture decision records (maintainer docs)
└── plugins/
    ├── joe-bag-of-tricks/
    │   ├── .claude-plugin/
    │   │   └── plugin.json       # plugin manifest (semver version)
    │   ├── skills/               # 21 skills
    │   └── agents/               # 7 agents
    └── joe-magic-bootstrap/
        ├── .claude-plugin/
        │   └── plugin.json       # plugin manifest (semver version)
        └── skills/               # 1 skill (project)
```

## Install on a machine

This is a **private** repo, so the marketplace clones over your GitHub credentials. The SSH URL form is the most reliable (it uses your SSH key directly):

```text
/plugin marketplace add git@github.com:jwp23/joe-bag-of-tricks.git
/plugin install joe-bag-of-tricks@joe-bag-of-tricks
/plugin install joe-magic-bootstrap@joe-bag-of-tricks
```

The `jwp23/joe-bag-of-tricks` shorthand also works if your git credential helper is configured (e.g. `gh auth setup-git`). For the SSH form, make sure your key is loaded in `ssh-agent` and `github.com` is in `~/.ssh/known_hosts`.

Plugins install at **user scope** by default, so the skills and agents are available in every project on that machine. Skills auto-trigger by description; you can also invoke them explicitly as `/joe-bag-of-tricks:<skill-name>`.

## Keep it in sync across machines

On the machine where you make changes:

```text
# edit skills/agents, then bump the version in plugins/joe-bag-of-tricks/.claude-plugin/plugin.json
git add -A
git commit -m "feat: <what changed>"
git push
```

On every other machine:

```text
/plugin marketplace update joe-bag-of-tricks
```

This git-pulls the marketplace and, because the plugin **version changed**, installs the update.

> **Versioning is explicit semver.** Bump `version` in `plugin.json` on every change you want to propagate. If the version string doesn't change, other machines keep their cached copy and won't update.

> **Optional background auto-update:** manual `/plugin marketplace update` uses your interactive git credentials. If you want the marketplace to refresh automatically at startup, that runs without credential helpers, so export a token with read access to the private repo (`export GITHUB_TOKEN=…` in your shell profile).

## Local development

Test changes against your live setup before pushing:

```text
/plugin marketplace add /path/to/joe-bag-of-tricks
/plugin install joe-bag-of-tricks@joe-bag-of-tricks
/plugin install joe-magic-bootstrap@joe-bag-of-tricks
/plugin validate /path/to/joe-bag-of-tricks
```

Use `/reload-plugins` to pick up local edits without restarting.

## Provenance & license

Licensed under the [MIT License](LICENSE).

Thirteen of the twenty-one skills are adapted from the [Superpowers](https://github.com/obra/superpowers) project by Jesse Vincent (MIT-licensed): `brainstorming`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `verification-before-completion`, `writing-plans`, and `writing-skills`.

The remaining skills (`implementer-contract`, `readme-sync`, `record-decision`, `scripted-browser-verification`, `security-review`, `using-skills`, `ux-audit`, `writing-agents`) and all six agents are original to this toolkit. Jesse Vincent's copyright notice is retained in `LICENSE` as required by the MIT License.
