# ADR-008: Plans Record Decisions, Not Code; Native Execution Joins Subagent-Driven at the Handoff

## Context

Upstream superpowers v6.4.1 and v6.4.2 changed the shape of a plan and how it is executed:

- **v6.4.2 — "A plan records decisions. It's not a transcript of the code."** A code step gives
  the exact signature, the file, and the spec's values; a body appears only for an algorithm those
  do not determine or exact copy the spec fixes. Self-review gained a Proportion check. Upstream's
  evidence: with full-code plans, Opus 5.5 under some prompting tried to implement the whole
  project while planning; signature-only plans took a quarter of the time and about a third of the
  tokens, and every one executed 9/9 against planted-defect probes on Sonnet 5 — the same result as
  full-code plans (upstream #2333).
- **v6.4.1 — Native (inline) execution rebuilt** as a real mode: the session implements every task
  itself under the same workspace and ledger as subagent-driven development, then dispatches one
  fresh whole-branch review on the most capable model. The plan handoff now offers Subagent-driven
  and Native, says what each costs, and recommends one. **Plans carry a Review Focus section** (up
  to five inputs or failure modes the spec implies but no task's tests exercise, each pinned by a
  test in the owning task), because in evals every implementer shipped the same crash on an input
  the spec implied but never named. And **the human reviews the saved plan before anything runs**
  — approving an idea or a scope no longer counts as approving a plan they haven't seen.

The fork had recorded the opposite stance on plan content on 2026-08-25 (issue #55, a note in
`docs/customizations.md`): briefs that carried the finished code ran at roughly a third of the
implementer cost of briefs that made the implementer discover it, and dispatched to the cheapest
tier (`implementer-mechanical`, which exists for transcription-grade briefs). The fork's
`executing-plans` was the 64-line stub upstream measured as equivalent to running no plugin, and
its writing-plans handoff went straight to subagent-driven execution with no review of the task
designs and no choice of method.

## Decision

1. **Follow upstream on plan content.** `writing-plans` now describes its reader as a capable
   engineer who writes idiomatic code once they know the exact interface and test; "What a Step
   Contains" replaces "No Placeholders"; a code step is a signature, a file, and the spec's values;
   self-review gains the Step scan and Proportion checks. The issue #55 cost note is superseded.
   The fork's own additions survive inside the new section: "invoke the X skill" / "run
   `/command`" remains a step that decides nothing, and record-decision is invoked by the planner,
   never as a task step.
2. **Review Focus lives on the epic**, in the same `--design` field as Global Constraints (the
   field is replaced on update, so both sections are written together), and each line is pinned
   by a test in the owning task. The final reviewer in both execution modes receives it verbatim.
3. **Native execution is a real mode**, ported from upstream with bd as the ledger: `bash
   scripts/task-start <task-id>` claims the bead, extracts the brief, and prints BASE; `bash
   scripts/task-done <task-id> BASE -- <test command>` runs the tests, keeps the log in the shared
   `.joe-bag-of-tricks/sdd/` workspace, and closes the bead with the commit range and test result
   as the reason — a failing run records nothing. Rulings are `bd note`s. The final whole-branch
   review dispatches on the top tier with the epic's Review Focus and the ruling notes, Critical
   and Important findings get one TDD-verified fix pass with no re-review, and delivery goes
   through `branch-shepherd` or `finishing-a-development-branch` exactly as subagent-driven
   development does.
4. **The handoff is a review gate with a choice.** `writing-plans` shows the hierarchy, asks the
   human partner to review it, offers Subagent-driven and Native with their costs and a
   one-sentence recommendation drawn from the plan, and honors a method already supplied. In plan
   mode, `ExitPlanMode` is that gate.

## Trade-offs

**Chosen: decisions-not-code plans, a review gate, and native execution as a choice**

- Planning gets cheaper and stops leaking into implementation; upstream's planted-defect result
  says execution quality holds.
- Native execution is the cheapest way to run a plan and runs well on a mid-tier session model;
  parallel bead crunches (`dispatching-parallel-agents`, `branch-shepherd`) are untouched — Native
  is a third option at the handoff, not a replacement for anything.
- A human sees the task designs before any of them run.

**Cost accepted: the mechanical implementer tier becomes rare.** `subagent-driven-development`
routes to `implementer-mechanical` by whether the brief already contains the code; under
decisions-not-code plans most tasks land on the standard `implementer`. The tier stays for exact
copy and spec-fixed algorithms, which a step may still carry. The issue #55 measurement (cheaper
implementation when the brief carries the code) is real and is being traded for cheaper, cleaner
planning; if implementer cost dominates a future epic, that is the number to revisit.

**Rejected: keep the fork's code-in-brief stance.** It optimizes the side of the trade upstream
showed to be the smaller one, and it kept producing plans that were transcripts of the program.

**Rejected: port Native without the handoff choice.** Upstream offers both; a mode nobody can
select is a stub again.
