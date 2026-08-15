# ADR-006: Defer Behavioral Evals; Script the Load-and-Observe Gate

## Context

This fork has no TDD and no automated evals. The validation floor is
`claude plugin validate` plus a hand-run smoke load, both recorded in
`.claude/rules/validating-changes.md`. The smoke load is one skill at a time, driven by eyeball
or by pasting a recipe, and it says nothing about the other 17 skills. Asking what evals should
look like here surfaced two separate questions: adopt upstream's eval harness, or build one.

**Upstream ships no evals to pull.** At `obra/superpowers` `v6.2.0` the `evals/` entry in
`.gitignore` is deliberate — the harness lives in its own repo,
`prime-radiant-inc/superpowers-evals` (harness name **Quorum**, bun/TypeScript), cloned into the
ignored `evals/` for local development. Upstream's `docs/testing.md` is **stale** where it
describes a Python/`uv`/`drill` harness; that was the pre-lift arrangement. `tests/` in upstream
is a different thing entirely — non-LLM integration tests for the brainstorm server, OpenCode
loading, and codex sync, most of which this fork does not carry.

**Quorum would work against this fork**, recorded here so a future revisit does not re-derive it:

- `coding-agents/claude-context/launch-agent` invokes
  `claude --dangerously-skip-permissions --plugin-dir "$SUPERPOWERS_ROOT"`, so
  `SUPERPOWERS_ROOT=plugins/joe-bag-of-tricks` is exactly right — the same plugin-root rule this
  fork's validation already follows.
- `quorum run|check|list|run-all` all accept `--scenarios-root`, and `run` accepts a scenario
  directory path, so fork-owned scenarios could live in this repo and be executed by an ignored
  harness clone.
- Skill detection (`src/detect/skill.ts`) is namespace-parameterized, so
  `joe-bag-of-tricks:<skill>` works without patching the harness.
- A scenario is three files: `story.md` (QA-agent brief + acceptance criteria), `setup.sh`
  (executable), `checks.sh` (sourced, `pre()`/`post()` only).

**Adopting it was still rejected**, on cost and fit. Quorum needs bun, tmux, and an API key;
runs agents in dangerous-permissions mode; takes 3–30+ minutes per scenario; and has nowhere to
run in CI — this repo has no `.github/workflows/` at all, the only PR check is the SonarCloud
app, and upstream explicitly forbids live evals in public CI. It also couples the fork to an
unversioned internal lab. Roughly half its ~80 scenarios target harnesses this fork does not
support.

**Licensing blocks vendoring regardless.** `prime-radiant-inc/superpowers-evals` is public but
has **no LICENSE** (`"license": null`) — all rights reserved. Under `docs/licensing.md` its
scenarios can never be vendored or adapted into this repo. Cloning it locally and running it is
what upstream instructs and is fine; committing any of its content here is not. Only
independently authored scenarios could ever live in this repo.

## Decision

**Defer behavioral evals.** Do not clone Quorum, do not author scenarios, do not fork the evals
repo.

Instead, close the gap that actually exists today: turn the manual smoke load into a scripted,
exit-code gate at `.claude/scripts/verify-skills-load.sh` that covers every skill in one
command, ordered divergence-first.

The gate drives one non-interactive session per skill and asserts on the structured stream, not
on reply prose:

```
claude --plugin-dir plugins/joe-bag-of-tricks --model sonnet --allowedTools Skill \
       --output-format stream-json --verbose \
       -p "Use the Skill tool to load the joe-bag-of-tricks:<name> skill, then reply DONE."
```

Three assertions per skill: a `Skill` tool_use carrying the fully namespaced name; a terminal
`result` with `subtype=success` and `is_error=false`; and a `SessionStart` `hook_response`
carrying the `using-skills` injection — which covers `hooks/session-start` and
`skills/using-skills`, both `replaced` files that `claude plugin validate` never reads. It also
hard-fails when a skill's frontmatter `name` disagrees with its directory name.

Run order comes from the `State` column of `docs/customizations.md`: `replaced` skills first,
then `patched`, then vendored and fork-original. The files this fork owns fail first.

Measured on the full 18-skill run: **57s** wall-clock at `--jobs 3`, **$2.75** total.
`--tier diverged` (12 skills) and `--only <name>` exist for tighter loops.

Two findings from building it, both worth keeping:

- A skill with `disable-model-invocation: true` (`writing-agents`, and `.claude/skills/upstream-sync`)
  is deliberately hidden from the model — the `Skill` tool **cannot** load it, and only
  `/namespace:name` reaches it. The gate detects the key and probes accordingly; the `VIA` column
  reports which mechanism was used, so the two are never silently conflated.
- The probe prompt must **forbid acting on the skill**. `requesting-code-review` acts the instant
  it loads: it dispatched a reviewer subagent, ran ten turns, and hit the timeout at $0.86 for one
  probe. With "do NOT follow the skill's instructions" in the prompt it is 5.4s and $0.14.
  Relatedly, `claude` has **no `--max-turns` flag** — the cap has to be prompt-level.

Assertion order matters for the same reason: **loading is primary**. A timeout or non-zero exit
does not short-circuit; the partial stream is still parsed, and a skill that loaded before the
session was cut off reports `PASS (loaded, but …)`. The gate claims a skill loads, so a messy
session ending after a successful load is not a failure of that claim.

**Scope boundary, stated plainly:** this gate proves a skill **loads when explicitly named**. It
does not prove a skill **triggers** from a natural prompt. Triggering is what the Quorum
`triggering-*` scenarios buy, and it is the regression an upstream sync is most likely to cause.
The gate is not an eval and no document should describe it as one.

## Trade-offs

**Chosen: defer evals, script the load gate**

- Costs nothing to stand up beyond one shell script; no bun, tmux, container, or second repo.
- Covers all 18 skills unattended and returns an exit code, so it cannot be half-skipped the way
  a hand-run recipe can.
- Asserts on structured JSON, so it fails for one reason and reports which — no prose matching
  that rots when a skill is reworded.
- Catches the specific class of breakage this fork actually produces: a skill that passes
  `claude plugin validate` but does not resolve or load after a sync, a rename, or a frontmatter
  edit.
- Cost: does not test triggering, multi-turn workflow behavior, worktree/SDD coordination, or
  anything under pressure — exactly the divergent behavior most worth testing. It buys presence,
  not correctness.
- Cost: every run is billed. Not suitable as a git pre-commit hook; it stays an explicitly-run
  gate.

**Rejected: adopt Quorum now**

- Technically feasible (see Context) and it is the only thing that tests real multi-turn
  behavior.
- But: unlicensed scenarios cannot be vendored, so every scenario would be written from scratch
  anyway; there is no CI to run them in; and the per-run cost and 3–30 min latency are the wrong
  shape for a solo plugin whose changes are mostly prose edits to skill bodies.
- Adds a standing dependency on an unversioned internal lab that can break this fork on any pull.

**Rejected: hand-roll a fuller behavioral harness**

- Would need multi-turn conversation control, fixtures, and an LLM judge — which is Quorum,
  rebuilt worse.
- Single-turn assertions are all a cheap harness buys, and that is what the load gate already
  does.

**Added, but advisory only: a triggering probe**

`.claude/scripts/probe-skill-triggering.sh` sends a natural prompt naming no skill and reports
which skill fired. It is the single-turn core of a `triggering-*` scenario, without the QA agent.

It **always exits 0** and is deliberately not in the pre-commit gate. That is not caution, it is
measured: across two runs of the same four prompts, `brainstorming` and `systematic-debugging`
hit 2/2, but `test-driven-development` and `writing-plans` hit **1/2** each — identical prompts,
different outcomes. A gate that flips like that would fail this project's pristine-output rule
every other run and train everyone to ignore it. Read it after a sync; do not gate on it.

*2026-08-14:* the four prompts were rewritten to the realistic-query standard and re-measured at
`--repeat 5`: `writing-plans` **3/5**, `test-driven-development` **1/5**. The `1/2` figures above
describe prompts that no longer exist in the repo — the flakiness conclusion is unchanged and
still stands, but do not read `1/2` as current. TDD did not merely stay flaky, it got worse, and
the meaning of a row that misses 80% of the time has to be written down or the probe becomes the
ignorable signal this ADR warns about. The candidate reading, consistent with all four rows but
not itself tested: hit rate tracks how much *situation* a description names. `systematic-debugging`
enumerates symptoms at length and `brainstorming` names the kinds of work it covers; both held at
2/2. `test-driven-development`'s entire description is twelve words of process — "Use when
implementing any feature or bugfix, before writing implementation code" — with no domain nouns for
a concrete request to match against, and it is the worst row. If that reading is right the fix is
the description, not the prompt, and the instrument for it is tier 2
(`example-skills:skill-creator`'s description-optimization loop), not another probe run. Until
someone does that, treat the TDD row as a known-open finding rather than noise.

Two things make the probe meaningful at all, both learned the hard way:

- It must run in a **neutral fixture repo**, which the script builds in a temp dir. Run in this
  repo, the project's own CLAUDE.md makes a generic coding prompt incoherent — the agent
  reasonably answers "a plugin repo has nowhere for an ISO-8601 validator to live" and never
  needs a skill. That reads as a triggering miss but is a fixture bug. This is exactly the
  `setup.sh` / fixture machinery a real harness provides and this fork chose not to build.
- The prompt must be **self-contained**. "I have a spec, turn it into a plan" makes the agent ask
  for the spec instead of planning; pasting the spec inline makes it plan. The probe tests the
  prompt at least as much as the skill.

## Revisit Trigger

Reopen this decision when any of these happen:

- A skill regression ships that a load check cannot catch — a skill that loads but stops
  triggering, or a multi-turn workflow (SDD, finishing-a-development-branch) that misbehaves in
  practice.
- `prime-radiant-inc/superpowers-evals` gains a license compatible with `docs/licensing.md`,
  which would remove the write-everything-from-scratch cost.
- This repo gains CI that could host evals, changing the cost calculus.
