# Debugging Discipline for Subagents

How root-cause debugging reaches the agents that do the work. Why it is shaped this way — the
transcript evidence, the platform probes, the rejected alternatives — is in
[`../decisions/debugger-agent-and-stop-conditions.md`](../decisions/debugger-agent-and-stop-conditions.md).

## The constraint

No subagent in this plugin holds the Skill tool. `/joe-bag-of-tricks:systematic-debugging` is
invocable only from a main session. A subagent gets the procedure one way: its agent definition
preloads the skill through `skills:` frontmatter. Preloading is paid on every dispatch of that
agent, so exactly one agent carries it, and work is routed to that agent.

## Components

### `debugger` agent

`plugins/joe-bag-of-tricks/agents/debugger.md`. Opus, high effort, the implementer tool
allowlist (`Bash, Read, Edit, Write, Grep, Glob`), `skills:` preloading `implementer-contract`
and `systematic-debugging`.

- **Input:** either a task brief path (a bug bead dispatched by SDD or a parallel batch) or a
  failure description with its evidence (a failing gate, a CI log, a BLOCKED branch's diagnosis).
  Always a working directory and a report-file path.
- **Output:** the implementer-contract report and short status contract, unchanged. A debugger
  that cannot establish a root cause reports BLOCKED with what it ruled out — it does not ship a
  fix for a cause it did not establish.
- **Depends on:** the preloaded skill's base-directory line to reach the skill's supporting
  files (`root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`).

It dispatches nothing and owns no tracker writes, like every implementer.

### Routing — who sends work to `debugger`

| Situation | Router | Rule |
|---|---|---|
| SDD task whose bead is `-t bug` | `subagent-driven-development` controller | Dispatch `debugger`. Never `implementer-mechanical`. |
| Parallel batch item whose bead is `-t bug` | `dispatching-parallel-agents` orchestrator | Dispatch `debugger`. |
| Parallel wave whose domains are failures to diagnose | `dispatching-parallel-agents` orchestrator | Dispatch `debugger` per domain, not `general-purpose`. |
| An implementer (any tier) reports BLOCKED / NEEDS_CONTEXT on a failure it could not explain | SDD controller | A wrong brief is fixed and re-dispatched as today; an undiagnosed failure goes to `debugger`. |
| Shepherd reports a branch BLOCKED on a failure that reproduces locally | the orchestrator that dispatched the shepherd | Dispatch `debugger` against that worktree, then re-dispatch the shepherd for the branch. |
| Shepherd reports a branch BLOCKED on a failure that does not reproduce locally | the orchestrator | Surfaces to the human partner with the named environment delta. No dispatch. |

`dispatching-parallel-agents` is a `patched` file; its routing rules live in the fork-owned
section, never in upstream's lines. SDD's review fix loop is unchanged — rounds, ladder, cap, and
breaker all stand.

### `implementer-mechanical` — never debugs

On a failure it did not expect, or a brief that contradicts what it finds in the code, the
mechanical tier reports BLOCKED or NEEDS_CONTEXT at the first contradiction. It does not form a
second hypothesis. The rule lives in the mechanical agent's own body, since it is the one thing
that differs from the other tiers.

### `implementer-contract` — verification before claiming

Applies to every tier. A factual claim an implementer ships — in a code comment, a stated
diagnosis, or a report — is one it observed, by running the thing or reading the code the claim
describes. A claim it only inferred is verified first or labelled as inferred.

### `branch-shepherd` — two stop conditions

Inside the existing bounded CI-fix loop (three attempts per branch), either of these ends the
loop for that branch immediately:

- the failure cannot be reproduced locally;
- a fix relocated the failure rather than resolving it.

The branch is reported BLOCKED with the diagnosis so far — naming the environment delta (runner
image, toolchain version, OS) when the failure does not reproduce — and the train moves on. The
shepherd holds no Agent tool and preloads no skill.

## Data flow

```
bug bead ──────────────────────────────► debugger ──► report ──► task review (unchanged)
feature bead ──► implementer tier ──► report ──► task review ──► fix loop (unchanged)
                      └ any-tier, unexpected failure ─► BLOCKED ─► controller ─► debugger
review-clean branches ──► shepherd ──► merged
                           └ stop condition ─► BLOCKED + diagnosis ─► orchestrator
                                                 ├ reproduces locally ─► debugger ─► shepherd again
                                                 └ does not reproduce ─► human partner
```

## Error handling

- `debugger` BLOCKED: the controller treats it as any top-of-ladder BLOCKED — a ruling, more
  context, or the human partner. There is no tier above it to escalate to.
- A `skills:` entry that fails to resolve is skipped silently by the harness. The check is the
  debug log's `Preloaded skill '<name>'` line for the `debugger` agent, not a canary question.

## Testing

Each behavior change owes a failing baseline before its fix
(`.claude/rules/authoring-skills-and-agents.md`). The baselines are fixture reproductions of
recorded runs:

| Change | Baseline fixture |
|---|---|
| Bug bead routing | A `-t bug` task whose ticket blames the wrong cause, run through SDD: observe which agent the controller dispatches. |
| Mechanical never debugs | A mechanical brief mandating a test that cannot pass: observe rewrite-and-delete versus NEEDS_CONTEXT. |
| Verification before claiming | A task whose obvious comment or diagnosis is false on inspection: observe whether the claim ships unchecked. |
| Shepherd stop conditions | A branch whose CI failure cannot reproduce locally (toolchain skew): observe per-symptom pushes versus BLOCKED naming the delta. |
| Parallel failure wave | Independent failing domains: observe `general-purpose` versus `debugger` dispatch. |
| `debugger` itself | The ticket-blames-wrong-cause fixture dispatched directly: observe reproduce-first and the disproved premise recorded in the report. |
