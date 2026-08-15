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
  (`plugins/joe-bag-of-tricks`)
- Adds beads-based workflow skills, a record-decision skill, and custom subagents
- Tracks superpowers upstream by release tag; may vendor other upstreams later
- Also ships `plugins/joe-magic-bootstrap`, a second, separate plugin with one skill (`project`)
  that interactively bootstraps a project's CLAUDE.md + `.claude/` structure

## What This Project Does NOT Do
- NOT multi-harness. Claude Code only — do not add/maintain Codex, Gemini, Cursor, Kimi,
  OpenCode, or Pi support; strip upstream's harness machinery (.codex-plugin,
  gemini-extension.json, .opencode, .pi, GEMINI.md)
- NOT composable. Skills/agents within `joe-bag-of-tricks` cross-reference; that plugin ships
  and installs as ONE unit — do not split it into separate plugins or rework its skills to be
  standalone. (This constraint is per-plugin: it does not forbid the marketplace from carrying
  a second, separate plugin like `joe-magic-bootstrap`.)
- NEVER vendor content whose license is unknown or incompatible. Preserve upstream
  copyright/license notices; record source + license in docs/customizations.md
- Ships skills, subagents, hooks. No commands/ — that pattern merged into skills

## Plugin Authoring
- Component dirs (skills/, agents/, hooks/) live at the plugin ROOT. NEVER inside
  .claude-plugin/ — only plugin.json goes there
- Authoring-only tooling (the upstream-sync skill, team rules) lives in .claude/ and is NOT
  shipped in the plugin
- Test locally: `claude --plugin-dir plugins/joe-bag-of-tricks` · Validate before distributing:
  `claude plugin validate plugins/joe-bag-of-tricks`. Both take the PLUGIN root, not the repo root
- Manifest schema and /joe-bag-of-tricks: namespacing: see the plugin spec above

## Upstream Sync
IMPORTANT: NEVER edit an upstream file to express a divergent workflow. Classify every
modified file in docs/customizations.md as vendored / patched / replaced.
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
No TDD and no behavioral evals — deferred by docs/adr/006-defer-behavioral-evals.md. Before any commit:
- `claude plugin validate plugins/joe-bag-of-tricks` — plugin manifest + skill frontmatter. Always.
  The path argument is REQUIRED. `claude plugin validate .` validates only the *marketplace*
  manifest and will NOT catch a broken skill.
- `.claude/scripts/verify-skills-load.sh` — loads every skill and asserts it resolved, divergent
  skills first; also asserts the SessionStart hook injected using-skills. `--only <name>` while
  iterating. One billed model call per skill. Proves a skill LOADS, not that it TRIGGERS.
  `--plugin-dir <plugin root>` targets another plugin; the namespace comes from its plugin.json.
  `--plugin-dir .` does NOT load the plugin — the repo root is the marketplace, and the script
  rejects it. Divergence ordering and `--tier diverged` need docs/customizations.md, which covers
  joe-bag-of-tricks only; elsewhere order is alphabetical and that tier is refused.
- `.claude/scripts/check-context-budget.sh` — hard fail when the always-loaded surface (skill
  descriptions + agent roster lines + the SessionStart injection) exceeds the committed token
  budget. Cheap; run it every time. SKILL.md bodies are reported, not gated.
- `plugins/joe-magic-bootstrap` has its own, identical validation gate:
  `claude plugin validate plugins/joe-magic-bootstrap`, run against its own plugin root, plus
  `.claude/scripts/verify-skills-load.sh --plugin-dir plugins/joe-magic-bootstrap`.
- Editing/creating a skill: follow /joe-bag-of-tricks:writing-skills.
NEVER claim a change works until you've loaded it and observed it — no "should work."
Inherited tests/pre-commit suites are kept-or-stripped per docs/customizations.md.

## Git Workflow
- Branches: feat/ fix/ docs/ chore/ refactor/ + short desc; sync/upstream-vX.Y.Z for upstream syncs
- Release tags are scoped per plugin: `<plugin-name>-vX.Y.Z` (e.g. `joe-bag-of-tricks-v1.0.1`,
  `joe-magic-bootstrap-v1.0.0`), matching each plugin's own `plugin.json` version. Tag on the
  version-bump commit. Pre-existing unscoped tags (`v0.1.0`–`v1.0.0`) predate the second plugin
  and are not retagged. See docs/decisions/per-plugin-scoped-release-tags.md
- Commits: Conventional Commits, single line, no body
- Squash-merge all feature branches, upstream syncs included. The fork shares no upstream
  ancestry, so a sync is an ordinary branch — no merge commit to preserve. See docs/adr/002-no-remote-upstream-sync.md
- Never push to main. Complete work via /joe-bag-of-tricks:finishing-a-development-branch.
  Done = PR open + CI green
See @.claude/rules/git-workflow.md for worktrees and merge policy.

## Dependencies
Pin engines.node ">=24". Commit any lockfile. Add dependencies sparingly — each one is
upstream-merge surface.

## Pre-commit & CI
Before commit: `betterleaks git --pre-commit --staged --redact` (hard fail) ·
`claude plugin validate plugins/joe-bag-of-tricks` ·
`claude plugin validate plugins/joe-magic-bootstrap` ·
`.claude/scripts/check-context-budget.sh` (always-loaded token budget) ·
`.claude/scripts/verify-skills-load.sh` (every skill loads; billed, so run it deliberately).
No markdown/shell/JS linters wired — upstream lints only its evals/, which is a gitignored clone
of a separate repo this fork does not carry (docs/adr/006-defer-behavioral-evals.md).
The **only** PR CI check is a **blocking SonarCloud quality gate** (a GitHub App integration — there
is no `.github/workflows/`, so `claude plugin validate` runs only *locally* as a pre-commit gate, not
in CI). A security/reliability/maintainability rating drop or an unreviewed hotspot on new code FAILS
the PR — it is not advisory. On failure, triage the gate: fix genuine issues; for false-positives or
accepted-by-design findings, mark them via the `sonarqube` MCP tools
(`change_sonar_issue_status` accept/falsepositive) with a justification recorded in
docs/customizations.md. CodeRabbit is not installed, so that finishing-branch step is a no-op.
The gate computes on **pull requests only**. A merge commit on `main` permanently reports check-run
`conclusion=neutral` / "Quality Gate not computed", and GitHub's legacy combined status reports
`state=pending` with `contexts=0` — an artifact of there being zero legacy statuses, NOT a running
job. This is steady state (identical on every merge commit), so never treat it as a failure and
never poll a merge commit waiting for it to settle — it will not. Judge CI by the PR's gate.

## Reference Documents
IMPORTANT: Before starting any task, identify which docs below are relevant and read them
first. Load the full context before making changes.
- docs/customizations.md — Read before any sync or before editing an inherited file.
  Per-file manifest: vendored/patched/replaced, with source, license, and reason(s).
- docs/upstream-sync.md — Read when syncing an upstream release. Full no-remote tag-diff/port
  procedure and resolution by manifest state. (The /upstream-sync skill points here.)
- docs/architecture.md — Read when unsure where a component belongs (root vs .claude/).
- docs/licensing.md — Read before vendoring from any upstream. Compatibility rules and the
  attribution/NOTICE discipline for a public repo.
- docs/skill-description-optimization.md — Read when a skill loads but triggers on the wrong
  prompts. On-demand skill-creator eval loop; not a gate. Cost model and eval-set conventions.

## Project Structure
Plugin layout and the root-vs-.claude/ split: see docs/architecture.md.
