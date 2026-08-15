# Adjudication

How an orchestrator settles a hard call without stalling the run and without trusting its own
sense of difficulty.

## The Problem

An orchestrator that fans out subagents collects conflicting claims: two reports that cannot
both be true, a finding that contradicts a recorded decision, a fix loop that will not
converge. Someone must rule, and the run must continue.

Letting the orchestrator decide when to escalate fails, because a model cannot reliably see
what it is missing. "This feels hard" is precisely the judgment it cannot make about itself,
and that limit holds at every tier — an orchestrator running on the top tier is as blind to its
own gaps as one running mid-tier. Escalation therefore fires on structural conditions the
orchestrator can detect by counting or comparing, never on self-assessed difficulty.

## The Adjudicator

`agents/adjudicator.md` pins `model: fable` and states the dispatch contract once. Both
orchestration skills dispatch it by name; neither restates what it does.

The agent definition carries the contract, not the triggers. An agent's body becomes the
subagent's system prompt, and the orchestrator sees only the name, description, and tool list
from the agent roster — so triggers placed there would be invisible to the one party that has
to fire them. Triggers live in the skills the orchestrator reads.

**Inputs.** The artifact file paths — brief, report, review, and the governing decision docs —
plus one narrow question naming every trigger that fired.

**Output.** A ruling, recorded by the orchestrator as
`bd note "Ruling: <what> — <why> — <cost if wrong>"`.

**Invariants.**

- Escalation is a dispatch, never a main-loop model switch. The session's model belongs to the
  maintainer, not to the orchestrator.
- Dispatch with clean context, never as a fork. A fork inherits the whole session; one such
  dispatch cost 249k tokens in the 2026-08 spe run, the worst single cost of that session.
- Several triggers firing at once produce ONE dispatch carrying one question packet.
- The ruling stands and the run continues. Rulings surface in the end-of-run roll-up, so the
  maintainer audits them after the run rather than during it.

## Triggers

| # | Fires when | Detected by |
|---|---|---|
| 1 | Two agents flatly contradict each other on a fact | Two reports asserting incompatible claims about the same artifact |
| 2 | An agent's output conflicts with a named governing decision | Comparison against the decisions named for this run |
| 3 | The fix loop hits its bound | A count, defined per path |
| 4 | A Critical finding touches data loss, security, or user files | The finding's own severity and subject |

`subagent-driven-development` states the table; `dispatching-parallel-agents` cross-references
it by namespace, the way that skill already cross-references SDD's Task Loop for its per-branch
review discipline. One statement, one place to edit.

Triggers 1, 2, and 4 read identically on every path. Trigger 3 counts differently depending on
what the path loops over, so each skill states its own bound and nothing else:

- **subagent-driven-development** — round 5 with findings still open.
- **dispatching-parallel-agents** — the same gate fails twice on one branch after a fix aimed
  at it. The gates are the project's committed ones: `claude plugin validate`,
  `verify-skills-load.sh`, `check-context-budget.sh`, and CI.

### Naming the governing decisions

Trigger 2 checks against a list the orchestrator names up front, in the batch setup or the task
brief: the task's own design, plus whichever recorded decisions bear on the work. Decisions
recorded during the run join the list as they are written. The adjudicator receives those paths
and reads the decision itself, rather than the orchestrator's paraphrase of it.

Bounding the list this way keeps the check mechanical. Comparing every report against all of
`docs/adr/` and `docs/decisions/` would be a scan the orchestrator could silently skip, which
is the failure mode the triggers exist to prevent.

Trigger 2 remains the weakest of the four, and deliberately so. The other three are settled by
counting or by comparing two reports; this one asks whether work violates a decision, and a
decision nobody named can still be violated unseen. That hole is accepted. The trigger earns
its place because the catch is one no review finding is guaranteed to surface: an agent adding
backward compatibility, or editing an upstream `replaced` file to express a divergent workflow,
breaks a standing decision while producing a diff that reviews clean.

## Scope

Adjudication belongs to the two skills that fan out subagents and collect their conflicts:
`subagent-driven-development` and `dispatching-parallel-agents`.

`executing-plans` and the shepherding agents — `branch-shepherd`, `coderabbit-reviewer`,
`pr-merger` — stay outside it. They run sequential, single-threaded work and produce no
cross-agent contradictions to settle.

Semantic conflicts between two branches editing the same file also stay outside it.
`branch-shepherd` already owns conflict reconciliation, and a trigger here would duplicate that
remit.

## Model Tiering

Fable is the adjudicator tier and appears nowhere else in the dispatch ladders. Implementers
cap at opus (`implementer-mechanical` → `implementer` → `implementer-complex`), and neither the
fix-loop escalation nor the BLOCKED ladder reaches past it. Extending the implementer ladder to
Fable would make it the default escalation for every stuck task and defeat the tiering;
structural triggers instead keep Fable dispatches rare and well-scoped.

See `../decisions/adjudicator-as-shared-agent.md` and `../decisions/orchestration-model-tiering.md`.
