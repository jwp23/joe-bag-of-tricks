# joe-bag-of-tricks

A personal, opinionated Claude Code plugin — a self-contained fork of obra/superpowers'
agentic-skills methodology, layered with custom beads-based workflow skills and subagents.
Installs as one unit; tracks upstream by release tag.

@AGENTS.md

## Tech Stack
Markdown skills/agents + Claude Code plugin manifest. Shell + Node ≥24 hooks (inherited).
Forked from obra/superpowers @ `8ea3981`, synced forward by release tag.
Plugin spec: https://code.claude.com/docs/en/plugins · Upstream: github.com/obra/superpowers

## What This Project Does
- Bundles inherited superpowers workflow skills (brainstorming, planning, TDD, systematic
  debugging, code review, branch finishing) plus custom additions into ONE installable plugin
- Adds beads-based workflow skills, a record-decision skill, and custom subagents
- Tracks superpowers upstream by release tag; may vendor other upstreams later

## What This Project Does NOT Do
- NOT multi-harness. Claude Code only — do not add/maintain Codex, Gemini, Cursor, Kimi,
  OpenCode, or Pi support; strip upstream's harness machinery (.codex-plugin,
  gemini-extension.json, .opencode, .pi, GEMINI.md)
- NOT composable. Skills/agents cross-reference; ships and installs as ONE unit. Do not split
  it into separate plugins or rework skills to be standalone
- NEVER vendor content whose license is unknown or incompatible. Preserve upstream
  copyright/license notices; record source + license in @docs/customizations.md
- Ships skills, subagents, hooks. No commands/ — that pattern merged into skills

## Plugin Authoring
- Component dirs (skills/, agents/, hooks/) live at the plugin ROOT. NEVER inside
  .claude-plugin/ — only plugin.json goes there
- Authoring-only tooling (the upstream-sync skill, team rules) lives in .claude/ and is NOT
  shipped in the plugin
- Test locally: `claude --plugin-dir .` · Validate before distributing: `claude plugin validate`
- Manifest schema and /joe-bag-of-tricks: namespacing: see the plugin spec above

## Upstream Sync
IMPORTANT: NEVER edit an upstream file to express a divergent workflow. Classify every
modified file in @docs/customizations.md as vendored / patched / replaced.
- Sync a release: invoke /upstream-sync (tag-merge, diff-driven classification, resolution)
- `patched` files diff-merge; `replaced` files are watch-and-port-by-hand, never auto-merged
- Classify by the git diff, NOT memory — a file may diverge for more than one reason

## Code Style
Author/edit skills via /joe-bag-of-tricks:writing-skills — lean SKILL.md, required
name/description frontmatter, progressive disclosure to supporting files. Don't freeform.
Match upstream's existing shell/Node style when editing inherited files — do NOT reformat
wholesale; bulk reformatting guarantees merge conflicts on the next sync.
Cross-reference skills/agents by namespace: /joe-bag-of-tricks:<name>.
IMPORTANT: When your preference conflicts with upstream's existing style, match upstream.

## Validation
No TDD and no automated evals for this repo yet. Before any commit:
- `claude plugin validate` — manifest/structure. Always.
- `claude --plugin-dir .` — load locally; confirm the changed skill/agent loads and triggers.
- Editing/creating a skill: follow /joe-bag-of-tricks:writing-skills.
NEVER claim a change works until you've loaded it and observed it — no "should work."
Inherited tests/pre-commit suites are kept-or-stripped per @docs/customizations.md.

## Git Workflow
- Branches: feat/ fix/ docs/ chore/ refactor/ + short desc; sync/upstream-vX.Y.Z for upstream syncs
- Commits: Conventional Commits, single line, no body
- Squash-merge all feature branches, upstream syncs included. The fork shares no upstream
  ancestry, so a sync is an ordinary branch — no merge commit to preserve. See @docs/adr/002-no-remote-upstream-sync.md
- Never push to main. Complete work via /joe-bag-of-tricks:finishing-a-development-branch.
  Done = PR open + CI green
See @.claude/rules/git-workflow.md for worktrees and merge policy.

## Dependencies
Pin engines.node ">=24". Commit any lockfile. Add dependencies sparingly — each one is
upstream-merge surface.

## Pre-commit & CI
Before commit: `betterleaks git --pre-commit --staged --redact` (hard fail) ·
`claude plugin validate` · `claude --plugin-dir .` smoke load.
No markdown/shell/JS linters wired — upstream lints only evals/, which this fork lacks.
CI on the PR runs `claude plugin validate` **and a blocking SonarCloud quality gate** — a
security/reliability/maintainability rating drop or an unreviewed hotspot on new code FAILS the PR
(it is not advisory). On failure, triage the gate: fix genuine issues; for false-positives or
accepted-by-design findings, mark them via the `sonarqube` MCP tools
(`change_sonar_issue_status` accept/falsepositive) with a justification recorded in
@docs/customizations.md. CodeRabbit is not installed, so that finishing-branch step is a no-op.

## Reference Documents
IMPORTANT: Before starting any task, identify which docs below are relevant and read them
first. Load the full context before making changes.
- @docs/customizations.md — Read before any sync or before editing an inherited file.
  Per-file manifest: vendored/patched/replaced, with source, license, and reason(s).
- @docs/upstream-sync.md — Read when syncing an upstream release. Full no-remote tag-diff/port
  procedure and resolution by manifest state. (The /upstream-sync skill points here.)
- @docs/architecture.md — Read when unsure where a component belongs (root vs .claude/).
- @docs/licensing.md — Read before vendoring from any upstream. Compatibility rules and the
  attribution/NOTICE discipline for a public repo.

## Project Structure
Plugin layout and the root-vs-.claude/ split: see @docs/architecture.md.
