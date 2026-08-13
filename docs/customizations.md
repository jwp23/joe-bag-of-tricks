# Customizations Manifest

Per-file record of how this fork diverges from upstream. **Read before any sync or before
editing an inherited file.** Source of truth for resolving sync deltas.

**Last synced:** `obra/superpowers` @ `v6.3.0` (synced 2026-08-13). The
next sync diffs `v6.3.0...<head>` via `gh api repos/obra/superpowers/compare/v6.3.0...<head>`; update
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
| plugins/joe-magic-bootstrap/** | fork-original | — | — | second, separate plugin (added 2026-08-08, one `project` skill + references). No upstream counterpart; nothing here participates in an upstream sync. Has its own `claude plugin validate` gate and its own scoped release tag |
| hooks/session-start + hooks/hooks.json | replaced | obra/superpowers | MIT | Claude-only fork of upstream's multi-harness SessionStart hook; injects `using-skills`; Cursor/Copilot/pi branching + `run-hook.cmd` polyglot wrapper stripped. v6.2.0: skipped the `"shell": "bash"` hook key — it exists to run upstream's `run-hook.cmd` polyglot wrapper, which this fork stripped; the fork invokes `hooks/session-start` (shebanged) directly |

## Skills — replaced (fork owns; read upstream for ideas, never auto-apply)

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/brainstorming | replaced | obra/superpowers | MIT | beads work-decomposition woven through spine. v6.1.1: ported visual-companion security hardening (session-key auth, realpath/symlink/hardlink containment, security headers, PID-ownership proof, frame cap, `--open`); stripped branding/telemetry (incl. external image fetch); adopted inline **spec self-review** (deleted spec-document-reviewer-prompt.md); preserved helper.js selection-indicator + `#claude-content`. v6.2.0: ported the YAGNI bullet into Design Exploration and dropped the redundant Key Principles roll-up; skipped the visual-companion Gemini CLI launch block (Claude-only fork). **2 fork hardenings AHEAD of upstream — preserve when re-porting server.cjs:** (1) `isAllowedHttpSite` Sec-Fetch-Site guard on the HTTP handler (upstream only guards the WS Origin); (2) `execFile` (not `cp.exec` string-concat) for `BRAINSTORM_OPEN_CMD`. 2026-08-08: moved to fully bead-driven development — retired the per-session `docs/specs/YYYY-MM-DD-<topic>-design.md` artifact entirely. `docs/designs/` now holds **living** design docs, one per subsystem/component (`docs/designs/<topic>.md`, no date prefix), updated in place on every change rather than accumulating dated snapshots; brainstorming checks `docs/designs/` first and creates vs. updates accordingly (new Process Flow decision diamond). The per-change spec (requirements, acceptance criteria, trade-offs) no longer lives in a markdown file at all — it moved into the bd epic's `--description`/`--design` fields, created alongside the epic in Work Decomposition. `--spec-id` on `bd create` (bd's own CLI flag name, unchanged) now links the epic back to the relevant living design doc as a reference pointer, not as "the spec" for the change. record-decision's approach-selection trigger (line 111) and the epic/feature decomposition structure were already correct and are unchanged by this pass. v6.3.0: ported the **Three Paths** classification (spike / bounded / architectural) — new HARD-GATE wording, Three Paths section, Red Flags table, per-path checklists, path-bound terminal states, graph classification nodes, "After the Design (architectural path)" retitle — adapted to bd: bounded = short in-chat design + ONE bd task, no design doc / no epic; architectural keeps the full living-design-doc + bd-epic flow; Plan Mode Integration renumbered to reference the architectural checklist. Skipped visual-companion.md's Copilot-CLI launch hunk (fork never carried the harness launch blocks). |
| skills/subagent-driven-development | replaced | obra/superpowers | MIT | 2026-08-09: Finish step now dispatches the fork-original `branch-shepherd` agent for unattended delivery of the finished branch, with finishing-a-development-branch kept as the interactive path; Dispatches roll-up added; noted that a parallel-batch item can itself be an SDD task. 2026-08-09: dispatch-economics + escalation section — controller runs mid-tier, escalation fires on *structural* triggers (breaker trip, finding-vs-design conflict, implementer/reviewer factual contradiction, Critical touching data loss/security/user files) never on self-assessed difficulty, resolved by one one-shot top-tier adjudicator dispatch whose ruling is recorded as a `bd note`; reviewer return contract (full report to file, ≤15 lines of verdicts + findings inline); forks banned for fix rounds; scratch-file capture for re-read command output. beads persistence at every node + model-selection additions. v6.1.1: ported task-scoped-review + strict-cost efficiency — merged task-reviewer (1 dispatch / 2 verdicts) default **sonnet** w/ opus-escalation net; new `scripts/{sdd-workspace,review-package,task-brief}` (task-brief rewritten to `bd show --json`); file-handoff report contract; durable progress via `bd note`/`bd close --reason` (no ledger file); deleted code-quality/spec reviewer prompts, added task-reviewer-prompt.md. v6.2.0: ported the **bounded fix loop** — 5 rounds max, rounds 1-3 resume the original implementer, 4-5 escalate to a fresh implementer one tier up, each round ends in a scoped re-review (new `re-review-prompt.md`, vendored + bd-adapted), then a breaker that adjudicates open findings (park-with-ruling or STOP on load-bearing); ledger entries expressed as `bd note`; restructured into Setup / Task Loop / Final Review / Finish + Common Rationalizations (dropped Advantages/Red Flags, folding the bd invariants into the steps). **Skipped upstream's plan-scoped workspace** (`.superpowers/sdd/<plan-basename>/` and the `PLAN_FILE` argument on all three scripts): it exists to stop one plan's ledger being misread as another's, and the fork has no ledger file — progress lives in bd, whose task IDs are globally unique, so briefs/reports cannot collide across plans. Script signatures stay `sdd-workspace` / `review-package BASE HEAD` / `task-brief TASK_ID`. 2026-08-08: replaced hardcoded "Joe" references with upstream's "your human partner" convention. v6.3.0: ported **rulings-not-stalls** — controller rules on conflicts/plan defects/plan-mandated findings instead of asking (`bd note "Ruling: ..."` convention, four stop classes, "Rulings I made" roll-up at Finish), reconciled with the fork's adjudicator (the adjudicator is now HOW a structural-trigger ruling gets made; the "reachable partner decides" precedence clause removed — see docs/decisions/sdd-rulings-not-stalls.md); also ported spec-as-binding-authority (epic `--spec-id` → living design doc), the preflight scan-as-table (recorded as epic bd note), batch-small-same-shape-work, bounded-stretch waiting guidance, the no-subagents dispatch bullet + rationalization rows. Prompts: implementer/task-reviewer/re-review all gained upstream's "You Do Not Dispatch Subagents" section near-verbatim; task-reviewer also gained the evidence-illegibility paragraph and the batched-dispatch file-by-file check. |
| skills/writing-plans | replaced | obra/superpowers | MIT | 2026-08-09: added "Survey by delegation, read by the slice" to File Structure — dispatch an Explore agent for the module survey, then Read only the specific functions a task design prescribes edits to, so survey tokens die with the subagent instead of being re-billed every planning turn. bd-hierarchy planning (the bd hierarchy IS the plan). v6.1.1: ported plan-crispness (Task Right-Sizing, Global Constraints on the epic, per-task Interfaces blocks, No Placeholders); adopted inline **self-review**, dropped the subagent plan-review loop (deleted plan-document-reviewer-prompt.md). v6.2.0: adopted the Remember-section deletion, preserving the fork's record-decision bullet as a one-liner. v6.3.0: ported the plan-header **Spec:** field idea as `--spec-id` on the ad-hoc epic-creation block ("the plan argues from the spec; executors read both") — the fork has no plan-file header to add it to |
| skills/executing-plans | replaced | obra/superpowers | MIT | bd-based execution. v6.1.1 change was a multi-harness note expansion — skipped. v6.2.0: ported the Step-1 worktree-first item and dropped the Integration roll-up |
| skills/finishing-a-development-branch | replaced | obra/superpowers | MIT | 2026-08-09: new "Orchestrating Multiple Branches" section at the top — Steps 1-2 (tests, security review, base-branch confirmation) stay per-branch in the main session; once branches are review-clean, delivery of Step 3-through-Merging hands off to the fork-original `branch-shepherd` agent (dispatched in the background, one branch or a train). Steps 3-5 remain the reference procedure branch-shepherd executes. PR-based flow (inline PR creation + pr-merger agent; no CI/CodeRabbit here). v6.1.1: ported Step-5 worktree-remove safety (cd to main root first, `prune`, `.worktrees/`-only guard). v6.2.0: ported the base-branch confirmation wording and replaced Common Mistakes + Red Flags with a Common Rationalizations table adapted to the PR flow; upstream's menu/discard/local-merge restructure does not apply (fork has no menu). Fork-only (2026-07-26): Steps 4/4.5 make the main-thread CI wait **unconditionally backgrounded** (`Bash` `run_in_background` + a `gh pr checks --json bucket` settle loop); the blocking `--watch` is removed from the skill entirely — an "unless you have nothing else to do" carve-out is a rationalization loophole, not a fallback. `--watch` is gone from the fork entirely. Step 3 now opens the PR inline (push + `gh pr create`) and the pr-creator agent is retired; every CI wait, initial run included, uses the one loop. See `adr/005-retire-pr-creator-single-ci-wait.md`. 2026-08-08: replaced hardcoded "Joe" references with upstream's "your human partner" convention. v6.3.0: ported the Step-5 removal-refused safety flow (never `--force`; show untracked files, ask commit/move/delete) + its rationalization row |
| skills/using-skills | replaced | obra/superpowers | MIT | fork rebrand of upstream `using-superpowers`; Claude-only, harness reference files (codex/gemini/pi/antigravity) dropped. v6.3.0: skipped the Hermes-Agent reference line (harness) |

## Skills — patched (fork diverged; reconcile upstream hunks by hand)

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| skills/writing-skills | patched | obra/superpowers | MIT | Anthropic skill-creator + best-practices (sidecar: anthropic-skill-creator.md). **Deliberate exception to adopt-by-default:** the v6.1.1 `Claude`→`agents` / CSO→SDO sweep is NOT adopted — heavy fork content + the Anthropic sidecar mean this file stays patched regardless, so hand-applying the 89-line sweep is high-effort/low-benefit. persuasion-principles `TodoWrite`→`todos` ported (removes a banned-tool ref). v6.2.0: adopted the Bottom Line deletion; skipped the skills-directory line rewrite (it adds codex/gemini reference links this fork drops — the fork's line already names `~/.claude/skills`). v6.3.0 (render-graphs.js): **adopted** `execFileSync` for both dot calls and the Windows-safe `dot -V` availability probe; **skipped** the CJS→ESM conversion — upstream's ESM only works via its repo-root `package.json` `"type": "module"`, which this fork intentionally drops, so `import` would throw at parse time here; kept `require()` |
| skills/systematic-debugging | patched | obra/superpowers | MIT | de-prefixed skill refs + record-decision hook + desc/argument-hint. v6.1.1: **adopted** `Ultra-think`. v6.2.0: **adopted** all hunks — overview trim, the Phase-4 verification-before-completion step (de-prefixed), Related-skills + Real-World-Impact removal. 2026-07-26: the fork-added `description` is now **double-quoted** — it contains `: ` (`mid-task:`), which as an unquoted YAML plain scalar failed to parse and made `claude plugin validate` fail with all frontmatter silently dropped. Keep it quoted when re-editing the description |
| skills/test-driven-development | patched | obra/superpowers | MIT | fork-added "Choose Test Level" section. v6.1.1: **adopted** the `[testing-anti-patterns.md](...)` markdown link (`@`-import is a CLAUDE.md mechanism, not a skill-body one). v6.2.0: **adopted** all hunks — `testing-anti-patterns.md` deleted and replaced by vendored `writing-good-tests.md`, Why-Order-Matters folded into the Common Rationalizations table |
| skills/receiving-code-review | patched | obra/superpowers | MIT | KEEPS the "Strange things are afoot at the Circle K" signal (skipped that deletion — Joe wants it) + desc. v6.1.1: **adopted** CLAUDE.md→instruction-file. v6.2.0: **adopted** the Bottom Line deletion |
| skills/verification-before-completion | patched | obra/superpowers | MIT | **Reclassified at v6.2.0 — previously (wrongly) listed as fork-original; it has had an upstream counterpart all along.** Fork delta: shortened description + a fork-added Visual Verification section. v6.2.0: **adopted** all hunks — overview trim, Why-This-Matters and Bottom Line removal |
| skills/dispatching-parallel-agents | patched | obra/superpowers | MIT | **Reclassified 2026-08-09 (was vendored through v6.2.0).** Fork appended two sections after upstream's Integration block: "Delivering Parallel Work (the bead-crunch pattern)" — one worktree/branch per independent item, per-branch review to clean, accumulate rather than deliver one-at-a-time, then ONE `branch-shepherd` dispatch with the full train — and "Choosing between this and subagent-driven-development" (deciding axis is dependency structure, not task count). Upstream's body above that point is unmodified, so upstream hunks diff-merge cleanly; keep the fork sections at the tail |
| skills/requesting-code-review | patched | obra/superpowers | MIT | **followed upstream** to general-purpose dispatch + improved template (incl. Read-Only Review guard); only fork adaptation is the `docs/plans/` example path. v6.2.0: **adopted** both hunks — intro trim and Integration-with-Workflows → Common Rationalizations. v6.3.0: **adopted** code-reviewer.md's "You Do Not Dispatch Subagents" section verbatim |

## Agents

| Path | State | Source | License | Reason(s) |
|------|-------|--------|---------|-----------|
| agents/code-reviewer.md | removed | obra/superpowers | MIT | followed upstream v6.1.1 removal; fork copy was byte-identical to base (zero custom value); reviews now dispatch a `general-purpose` subagent |
| agents/branch-shepherd.md | fork-original | — | — | no upstream counterpart. Added 2026-08-09: autonomous multi-branch delivery (push → PR → CI → CodeRabbit → conflict reconciliation → squash-merge → worktree cleanup), dispatched with a branch list by `finishing-a-development-branch`, `subagent-driven-development`, and `dispatching-parallel-agents` |
| agents/coderabbit-reviewer.md, pr-merger.md | fork-original | — | — | no upstream counterpart (merge/CodeRabbit automation). 2026-08-08: pr-merger.md had a hardcoded "Joe" reference; replaced with "your human partner" |
| agents/pr-creator.md | removed | — | — | fork-original, retired 2026-07-26 — PR creation folded inline into `finishing-a-development-branch` Step 3. See `adr/005-retire-pr-creator-single-ci-wait.md` |

## Fork-original skills (no upstream counterpart)

`readme-sync`, `record-decision`, `security-review`, `writing-agents` — fork additions; no
upstream file to diff against. 2026-08-08: `record-decision` had hardcoded "Joe" references;
replaced with upstream's "your human partner" convention (already used throughout the rest of
the plugin) so the personalization doesn't leak into a redistributable skill. 2026-08-08:
`security-review/security-reviewer.md` (the subagent-dispatch prompt used by
finishing-a-development-branch Step 1.5) gained a "Working Directory Safety" clause forbidding
`git checkout`/`switch`/`pull`/`fetch`/`merge` — observed a dispatched reviewer subagent run
`git checkout main && git pull` in the shared working directory mid-session, moving HEAD off the
branch the main session had checked out. See `docs/decisions/security-reviewer-shared-worktree-safety.md`.

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

v6.2.0: `dispatching-parallel-agents/SKILL.md` was taken to head again (byte-identical to v6.2.0)
— **but it has since diverged and moved to the patched table above (2026-08-09); do not take it to
head.** `test-driven-development/testing-anti-patterns.md` was byte-identical to v6.1.1 and follows
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
  `.cursor-plugin/`, `.devin-plugin/`, `.hermes-plugin/`, `.agents/`, `gemini-extension.json`,
  `hooks/hooks-cursor.json`, `hooks/run-hook.cmd`: this fork is Claude-Code-only.
- **Harness docs** — `docs/README.{codex,kimi,opencode}.md`, `docs/porting-to-a-new-harness.md`,
  `docs/testing.md`, `docs/windows/`, and the
  `references/{codex,gemini,antigravity,pi,hermes}-tools.md` under `using-superpowers`.
- **Upstream dev archive** — `docs/superpowers/plans/*`, `docs/superpowers/specs/*` (upstream's
  internal planning; read as reference during a sync, never vendored).
- **Project scaffolding** — `package.json` (multi-harness bootstrap, 0 deps, not used by the
  visual companion), `.pre-commit-config.yaml`, `.version-bump.json`, `scripts/*`, `tests/*`,
  `commands/*`, `CHANGELOG.md`, `RELEASE-NOTES.md`, `.github/ISSUE_TEMPLATE/*`,
  `.github/PULL_REQUEST_TEMPLATE.md`, `assets/*` (superpowers branding).
- **.gitignore** additions from v6.1.1 (`.superpowers/`, `evals/`) and v6.3.0 (Python/pytest
  entries for upstream's hermes tests) — none apply to this fork.

<!-- Add a row for every file a sync touches. Classify by the upstream diff, not memory. -->
