# Customizations Manifest

Per-file record of how this fork diverges from upstream. **Read before any sync or before
editing an inherited file.** Source of truth for resolving sync deltas.

**Last synced:** `obra/superpowers` @ `v6.2.0` (synced 2026-07-26). The
next sync diffs `v6.2.0...<head>` via `gh api repos/obra/superpowers/compare/v6.2.0...<head>`; update
this to the head ref after each sync — it is the anchor that keeps the next diff small (see
`adr/002-no-remote-upstream-sync.md`).

Paths are **fork paths**. Plugin payload is nested under `plugins/joe-bag-of-tricks/`; repo-level
files (CLAUDE.md, AGENTS.md, …) stay at the repo root. Skill paths below are shortened to
`skills/<name>` — read as `plugins/joe-bag-of-tricks/skills/<name>`.

States: `vendored` (take upstream wholesale) · `patched` (reconcile by hand; edits in place or in a
sidecar file) · `replaced` (yours wins; read upstream for ideas and port by hand, never apply) ·
`removed` (fork dropped it, following upstream or by choice) · `fork-original` (no upstream
counterpart).

**Overarching sync policy (set 2026-07-19, revised same day):** **adopt upstream's wording by
default**, platform-neutralizations included (`Task()`→`Subagent`, "CLAUDE.md"→"instruction-file",
`Claude`→`agents`, `@import`→markdown-link, etc.). Keep a Claude-specific term only when (a) Joe
explicitly wants it (e.g. the "Strange things are afoot at the Circle K" signal) or (b) it has a
*verified* Claude-Code functional effect. Rationale: most "neutralizations" are cosmetic or are
actually upstream improvements, and keeping Claude-specific prose creates permanent per-line sync
friction for negligible gain — so the default is *adopt*, not *skip*. This supersedes the initial
"selective/skip-neutralization" stance. Independent **code** review is still kept everywhere;
**plan/spec** review moved to inline self-review (see `adr/003-...`; upstream evidence: ~25 min/run
overhead, no measurable quality gain across 25 trials). **Follow upstream on genuine efficiency or
security wins.**

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
| hooks/session-start + hooks/hooks.json | replaced | obra/superpowers | MIT | Claude-only fork of upstream's multi-harness SessionStart hook; injects `using-skills`; Cursor/Copilot/pi branching + `run-hook.cmd` polyglot wrapper stripped. v6.2.0: skipped the `"shell": "bash"` hook key — it exists to run upstream's `run-hook.cmd` polyglot wrapper, which this fork stripped; the fork invokes `hooks/session-start` (shebanged) directly |

## Skills — replaced (fork owns; read upstream for ideas, never auto-apply)

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/brainstorming | replaced | obra/superpowers | MIT | beads work-decomposition woven through spine. v6.1.1: ported visual-companion security hardening (session-key auth, realpath/symlink/hardlink containment, security headers, PID-ownership proof, frame cap, `--open`); stripped branding/telemetry (incl. external image fetch); adopted inline **spec self-review** (deleted spec-document-reviewer-prompt.md); preserved helper.js selection-indicator + `#claude-content`. v6.2.0: ported the YAGNI bullet into Design Exploration and dropped the redundant Key Principles roll-up; skipped the visual-companion Gemini CLI launch block (Claude-only fork). **2 fork hardenings AHEAD of upstream — preserve when re-porting server.cjs:** (1) `isAllowedHttpSite` Sec-Fetch-Site guard on the HTTP handler (upstream only guards the WS Origin); (2) `execFile` (not `cp.exec` string-concat) for `BRAINSTORM_OPEN_CMD` |
| skills/subagent-driven-development | replaced | obra/superpowers | MIT | beads persistence at every node + model-selection additions. v6.1.1: ported task-scoped-review + strict-cost efficiency — merged task-reviewer (1 dispatch / 2 verdicts) default **sonnet** w/ opus-escalation net; new `scripts/{sdd-workspace,review-package,task-brief}` (task-brief rewritten to `bd show --json`); file-handoff report contract; durable progress via `bd note`/`bd close --reason` (no ledger file); deleted code-quality/spec reviewer prompts, added task-reviewer-prompt.md. v6.2.0: ported the **bounded fix loop** — 5 rounds max, rounds 1-3 resume the original implementer, 4-5 escalate to a fresh implementer one tier up, each round ends in a scoped re-review (new `re-review-prompt.md`, vendored + bd-adapted), then a breaker that adjudicates open findings (park-with-ruling or STOP on load-bearing); ledger entries expressed as `bd note`; restructured into Setup / Task Loop / Final Review / Finish + Common Rationalizations (dropped Advantages/Red Flags, folding the bd invariants into the steps). **Skipped upstream's plan-scoped workspace** (`.superpowers/sdd/<plan-basename>/` and the `PLAN_FILE` argument on all three scripts): it exists to stop one plan's ledger being misread as another's, and the fork has no ledger file — progress lives in bd, whose task IDs are globally unique, so briefs/reports cannot collide across plans. Script signatures stay `sdd-workspace` / `review-package BASE HEAD` / `task-brief TASK_ID`. 2026-08-08: replaced hardcoded "Joe" references with upstream's "your human partner" convention |
| skills/writing-plans | replaced | obra/superpowers | MIT | bd-hierarchy planning (the bd hierarchy IS the plan). v6.1.1: ported plan-crispness (Task Right-Sizing, Global Constraints on the epic, per-task Interfaces blocks, No Placeholders); adopted inline **self-review**, dropped the subagent plan-review loop (deleted plan-document-reviewer-prompt.md). v6.2.0: adopted the Remember-section deletion, preserving the fork's record-decision bullet as a one-liner |
| skills/executing-plans | replaced | obra/superpowers | MIT | bd-based execution. v6.1.1 change was a multi-harness note expansion — skipped. v6.2.0: ported the Step-1 worktree-first item and dropped the Integration roll-up |
| skills/finishing-a-development-branch | replaced | obra/superpowers | MIT | PR-based flow (inline PR creation + pr-merger agent; no CI/CodeRabbit here). v6.1.1: ported Step-5 worktree-remove safety (cd to main root first, `prune`, `.worktrees/`-only guard). v6.2.0: ported the base-branch confirmation wording and replaced Common Mistakes + Red Flags with a Common Rationalizations table adapted to the PR flow; upstream's menu/discard/local-merge restructure does not apply (fork has no menu). Fork-only (2026-07-26): Steps 4/4.5 make the main-thread CI wait **unconditionally backgrounded** (`Bash` `run_in_background` + a `gh pr checks --json bucket` settle loop); the blocking `--watch` is removed from the skill entirely — an "unless you have nothing else to do" carve-out is a rationalization loophole, not a fallback. `--watch` is gone from the fork entirely. Step 3 now opens the PR inline (push + `gh pr create`) and the pr-creator agent is retired; every CI wait, initial run included, uses the one loop. See `adr/005-retire-pr-creator-single-ci-wait.md`. 2026-08-08: replaced hardcoded "Joe" references with upstream's "your human partner" convention |
| skills/using-skills | replaced | obra/superpowers | MIT | fork rebrand of upstream `using-superpowers`; Claude-only, harness reference files (codex/gemini/pi/antigravity) dropped |

## Skills — patched (fork diverged; reconcile upstream hunks by hand)

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/writing-skills | patched | obra/superpowers | MIT | Anthropic skill-creator + best-practices (sidecar: anthropic-skill-creator.md). **Deliberate exception to adopt-by-default:** the v6.1.1 `Claude`→`agents` / CSO→SDO sweep is NOT adopted — heavy fork content + the Anthropic sidecar mean this file stays patched regardless, so hand-applying the 89-line sweep is high-effort/low-benefit. persuasion-principles `TodoWrite`→`todos` ported (removes a banned-tool ref). v6.2.0: adopted the Bottom Line deletion; skipped the skills-directory line rewrite (it adds codex/gemini reference links this fork drops — the fork's line already names `~/.claude/skills`) |
| skills/systematic-debugging | patched | obra/superpowers | MIT | de-prefixed skill refs + record-decision hook + desc/argument-hint. v6.1.1: **adopted** `Ultra-think`. v6.2.0: **adopted** all hunks — overview trim, the Phase-4 verification-before-completion step (de-prefixed), Related-skills + Real-World-Impact removal. 2026-07-26: the fork-added `description` is now **double-quoted** — it contains `: ` (`mid-task:`), which as an unquoted YAML plain scalar failed to parse and made `claude plugin validate` fail with all frontmatter silently dropped. Keep it quoted when re-editing the description |
| skills/test-driven-development | patched | obra/superpowers | MIT | fork-added "Choose Test Level" section. v6.1.1: **adopted** the `[testing-anti-patterns.md](...)` markdown link (`@`-import is a CLAUDE.md mechanism, not a skill-body one). v6.2.0: **adopted** all hunks — `testing-anti-patterns.md` deleted and replaced by vendored `writing-good-tests.md`, Why-Order-Matters folded into the Common Rationalizations table |
| skills/receiving-code-review | patched | obra/superpowers | MIT | KEEPS the "Strange things are afoot at the Circle K" signal (skipped that deletion — Joe wants it) + desc. v6.1.1: **adopted** CLAUDE.md→instruction-file. v6.2.0: **adopted** the Bottom Line deletion |
| skills/verification-before-completion | patched | obra/superpowers | MIT | **Reclassified at v6.2.0 — previously (wrongly) listed as fork-original; it has had an upstream counterpart all along.** Fork delta: shortened description + a fork-added Visual Verification section. v6.2.0: **adopted** all hunks — overview trim, Why-This-Matters and Bottom Line removal |
| skills/requesting-code-review | patched | obra/superpowers | MIT | **followed upstream** to general-purpose dispatch + improved template (incl. Read-Only Review guard); only fork adaptation is the `docs/plans/` example path. v6.2.0: **adopted** both hunks — intro trim and Integration-with-Workflows → Common Rationalizations |

## Agents

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| agents/code-reviewer.md | removed | obra/superpowers | MIT | followed upstream v6.1.1 removal; fork copy was byte-identical to base (zero custom value); reviews now dispatch a `general-purpose` subagent |
| agents/coderabbit-reviewer.md, pr-merger.md | fork-original | — | — | no upstream counterpart (merge/CodeRabbit automation). 2026-08-08: pr-merger.md had a hardcoded "Joe" reference; replaced with "your human partner" |
| agents/pr-creator.md | removed | — | — | fork-original, retired 2026-07-26 — PR creation folded inline into `finishing-a-development-branch` Step 3. See `adr/005-retire-pr-creator-single-ci-wait.md` |

## Fork-original skills (no upstream counterpart)

`readme-sync`, `record-decision`, `security-review`, `writing-agents` — fork additions; no
upstream file to diff against. 2026-08-08: `record-decision` had hardcoded "Joe" references;
replaced with upstream's "your human partner" convention (already used throughout the rest of
the plugin) so the personalization doesn't leak into a redistributable skill.

## Vendored skills (== upstream head; take head each sync)

Skills not listed above are vendored. v6.1.1: `dispatching-parallel-agents/SKILL.md`,
`systematic-debugging/root-cause-tracing.md`, and `systematic-debugging/CREATION-LOG.md` were all
brought to head and are now byte-identical to v6.1.1 (`dispatching-parallel-agents` dropped from
patched to vendored under the adopt-by-default policy). `writing-skills/persuasion-principles.md` is
covered by the writing-skills (patched) row.

v6.2.0: `using-git-worktrees/SKILL.md` **dropped from patched to vendored** — taken to head
wholesale (byte-identical to v6.2.0). The fork had been carrying upstream's pre-v6.1.1 spine with
only Step-0 detection ported in, which left a Quick Reference row (`Neither exists | Check CLAUDE.md
→ Ask user`) contradicting both the fork's own `.worktrees/`-always convention and the section above
it, and declined the native-tool deferral (`EnterWorktree`) that upstream calls the #1 mistake to
skip. Joe's call (2026-07-26): follow upstream. The remaining tension — upstream's consent prompt vs
the fork's do-not-ask convention — is resolved *outside* the skill: upstream's own wording honors an
existing declared preference without asking, and `.claude/rules/git-workflow.md` now declares it
explicitly. See `adr/004-vendor-using-git-worktrees.md`.

v6.2.0: `dispatching-parallel-agents/SKILL.md` taken to head again (byte-identical to v6.2.0).
`test-driven-development/testing-anti-patterns.md` was byte-identical to v6.1.1 and follows
upstream's removal; its replacement `test-driven-development/writing-good-tests.md` is vendored at
v6.2.0. `systematic-debugging/find-polluter.sh` was already byte-identical to v6.1.1; its v6.2.0
change was taken to head. `subagent-driven-development/re-review-prompt.md` is a NEW upstream file,
vendored with bd/script-signature adaptations — tracked under the SDD (replaced) row, not here.

## SonarCloud (CI gate) — accepted findings on the visual-companion server

The PR CI runs a **blocking** SonarCloud quality gate. The visual-companion server (`brainstorming/
scripts/server.cjs`, `helper.js`) trips several SECURITY rules that are false-positives or upstream-
documented design choices — all reviewed and **marked accepted/false-positive in SonarCloud** (2026-07,
PR #6). If a future `server.cjs` re-port re-raises them, re-accept rather than "fixing" by design change:

- **S5332** `http://` / `ws://` (helper.js, server.cjs) — the companion is a **localhost** server;
  upstream's explicit non-goal is "no HTTPS/wss". Accepted.
- **S5443** publicly-writable dir — the `/tmp/brainstorm` default is a **dev-only fallback**; normal
  launch via `start-server.sh` sets `BRAINSTORM_DIR` to a `umask 077` project-local dir, key file
  `0600`, realpath-contained. Accepted.
- **S5131** reflect user data / **S2245** pseudorandom — these two were **fixed in code** (emit the
  validated `TOKEN` not the echoed request key; `crypto.randomInt` for the port), not accepted.

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
