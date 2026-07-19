# Customizations Manifest

Per-file record of how this fork diverges from upstream. **Read before any sync or before
editing an inherited file.** Source of truth for resolving sync deltas.

**Last synced:** `obra/superpowers` @ `v6.1.1` (synced 2026-07-19 from fork point `8ea3981`). The
next sync diffs `v6.1.1...<head>` via `gh api repos/obra/superpowers/compare/v6.1.1...<head>`; update
this to the head ref after each sync — it is the anchor that keeps the next diff small (see
`adr/002-no-remote-upstream-sync.md`).

Paths are **fork paths**. Plugin payload is nested under `plugins/joe-bag-of-tricks/`; repo-level
files (CLAUDE.md, AGENTS.md, …) stay at the repo root. Skill paths below are shortened to
`skills/<name>` — read as `plugins/joe-bag-of-tricks/skills/<name>`.

States: `vendored` (take upstream wholesale) · `patched` (reconcile by hand; edits in place or in a
sidecar file) · `replaced` (yours wins; read upstream for ideas and port by hand, never apply) ·
`removed` (fork dropped it, following upstream or by choice) · `fork-original` (no upstream
counterpart).

**Overarching sync policy (set 2026-07-19):** *selective* on pure platform-neutralization — this is a
Claude-Code-only fork, so skip de-Claude-ification (`Task()`→generic `Subagent`, "CLAUDE.md"→
"instruction-file", `Claude`→`agents`, `@import`→markdown-link) — but **follow upstream where the
change is a genuine efficiency or security win**. Independent-subagent **code** review is kept
everywhere; **plan/spec** review moved to inline self-review (upstream evidence: ~25 min/run overhead,
no measurable quality gain across 25 trials).

## Repo-level files

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| AGENTS.md | replaced | obra/superpowers | MIT | upstream only points to CLAUDE.md; this carries the full beads workflow |
| CLAUDE.md | replaced | obra/superpowers | MIT | fork's own project instructions; upstream's v6.1.1 CLAUDE.md is *their* contributor policy — skip |
| README.md | replaced | obra/superpowers | MIT | fork's own README; upstream's is multi-harness install + superpowers branding — skip |
| .claude-plugin/marketplace.json | replaced | obra/superpowers | MIT | fork's own marketplace listing |

## Plugin manifest & hooks

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| .claude-plugin/plugin.json (plugin root) | replaced | obra/superpowers | MIT | fork identity/branding (name, version, author); upstream's carries multi-harness bootstrap |
| hooks/session-start + hooks/hooks.json | replaced | obra/superpowers | MIT | Claude-only fork of upstream's multi-harness SessionStart hook; injects `using-skills`; Cursor/Copilot/pi branching + `run-hook.cmd` polyglot wrapper stripped |

## Skills — replaced (fork owns; read upstream for ideas, never auto-apply)

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/brainstorming | replaced | obra/superpowers | MIT | beads work-decomposition woven through spine. v6.1.1: ported visual-companion security hardening (session-key auth, realpath/symlink/hardlink containment, security headers, PID-ownership proof, frame cap, `--open`); stripped branding/telemetry (incl. external image fetch); adopted inline **spec self-review** (deleted spec-document-reviewer-prompt.md); preserved helper.js selection-indicator + `#claude-content` |
| skills/subagent-driven-development | replaced | obra/superpowers | MIT | beads persistence at every node + model-selection additions. v6.1.1: ported task-scoped-review + strict-cost efficiency — merged task-reviewer (1 dispatch / 2 verdicts) default **sonnet** w/ opus-escalation net; new `scripts/{sdd-workspace,review-package,task-brief}` (task-brief rewritten to `bd show --json`); file-handoff report contract; durable progress via `bd note`/`bd close --reason` (no ledger file); deleted code-quality/spec reviewer prompts, added task-reviewer-prompt.md |
| skills/writing-plans | replaced | obra/superpowers | MIT | bd-hierarchy planning (the bd hierarchy IS the plan). v6.1.1: ported plan-crispness (Task Right-Sizing, Global Constraints on the epic, per-task Interfaces blocks, No Placeholders); adopted inline **self-review**, dropped the subagent plan-review loop (deleted plan-document-reviewer-prompt.md) |
| skills/executing-plans | replaced | obra/superpowers | MIT | bd-based execution. v6.1.1 change was a multi-harness note expansion — skipped |
| skills/finishing-a-development-branch | replaced | obra/superpowers | MIT | PR-based flow (pr-creator/pr-merger agents; no CI/CodeRabbit here). v6.1.1: ported Step-5 worktree-remove safety (cd to main root first, `prune`, `.worktrees/`-only guard) |
| skills/using-skills | replaced | obra/superpowers | MIT | fork rebrand of upstream `using-superpowers`; Claude-only, harness reference files (codex/gemini/pi/antigravity) dropped |

## Skills — patched (fork diverged; reconcile upstream hunks by hand)

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/writing-skills | patched | obra/superpowers | MIT | Anthropic skill-creator + best-practices (sidecar: anthropic-skill-creator.md). v6.1.1: evaluated, **skipped wholesale** (pure `Claude`→`agents` / CSO→SDO neutralization + cosmetic link tweaks); ported persuasion-principles `TodoWrite`→`todos` (removes a banned-tool ref) |
| skills/systematic-debugging | patched | obra/superpowers | MIT | de-prefixed skill refs + record-decision hook + desc/argument-hint. v6.1.1: skipped `Ultrathink`→`Ultra-think` (Claude thinking trigger) |
| skills/test-driven-development | patched | obra/superpowers | MIT | fork-added "Choose Test Level" section. v6.1.1: skipped `@testing-anti-patterns.md`→markdown-link (keeps Claude auto-import) |
| skills/receiving-code-review | patched | obra/superpowers | MIT | KEEPS the "Strange things are afoot at the Circle K" signal + desc. v6.1.1: skipped CLAUDE.md→instruction-file and the Circle-K deletion |
| skills/using-git-worktrees | patched | obra/superpowers | MIT | `.worktrees/`-always convention (do not ask). v6.1.1: ported Step-0 existing-isolation detection; skipped native-tools/ask-consent |
| skills/dispatching-parallel-agents | patched | obra/superpowers | MIT | v6.1.1: ported the one-response=parallel clarification; kept Claude `Task()` form (skipped `Task()`→generic `Subagent`) |
| skills/requesting-code-review | patched | obra/superpowers | MIT | **followed upstream** to general-purpose dispatch + improved template (incl. Read-Only Review guard); only fork adaptation is the `docs/plans/` example path |

## Agents

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| agents/code-reviewer.md | removed | obra/superpowers | MIT | followed upstream v6.1.1 removal; fork copy was byte-identical to base (zero custom value); reviews now dispatch a `general-purpose` subagent |
| agents/coderabbit-reviewer.md, pr-creator.md, pr-merger.md | fork-original | — | — | no upstream counterpart (PR/merge/CodeRabbit automation) |

## Fork-original skills (no upstream counterpart)

`readme-sync`, `record-decision`, `security-review`, `verification-before-completion`,
`writing-agents` — fork additions; no upstream file to diff against.

## Vendored skills (pristine == base; take upstream head next sync)

Skills not listed above are vendored. v6.1.1 touched `systematic-debugging/root-cause-tracing.md`
and `systematic-debugging/CREATION-LOG.md` with cosmetic `/Users/jesse/`→`~/` de-personalization
only — **skipped** (still pristine == base); `writing-skills/persuasion-principles.md` is covered by
the writing-skills (patched) row.

## Dropped upstream paths (never carried; skip on every sync)

Intentionally not vendored — record why here so future syncs don't re-litigate:

- **Harness dirs & configs** — `.codex-plugin/`, `.opencode/`, `.pi/`, `.kimi-plugin/`,
  `.cursor-plugin/`, `.agents/`, `gemini-extension.json`, `hooks/hooks-cursor.json`,
  `hooks/run-hook.cmd`: this fork is Claude-Code-only.
- **Harness docs** — `docs/README.{codex,kimi,opencode}.md`, `docs/porting-to-a-new-harness.md`,
  `docs/testing.md`, `docs/windows/`, and the `references/{codex,gemini,antigravity,pi}-tools.md`
  under `using-superpowers`.
- **Upstream dev archive** — `docs/superpowers/plans/*`, `docs/superpowers/specs/*` (upstream's
  internal planning; read as reference during a sync, never vendored).
- **Project scaffolding** — `package.json` (multi-harness bootstrap, 0 deps, not used by the
  visual companion), `.pre-commit-config.yaml`, `.version-bump.json`, `scripts/*`, `tests/*`,
  `commands/*`, `CHANGELOG.md`, `RELEASE-NOTES.md`, `.github/ISSUE_TEMPLATE/*`,
  `.github/PULL_REQUEST_TEMPLATE.md`, `assets/*` (superpowers branding).
- **.gitignore** additions from v6.1.1 (`.superpowers/`, `evals/`) — neither applies to this fork.

<!-- Add a row for every file a sync touches. Classify by the upstream diff, not memory. -->
