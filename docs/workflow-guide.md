# Workflow Guide — What You Type, End to End

**Read when you want the hands-on-keyboard version** of how these skills and agents fit
together, not the per-skill reference. Each skill's own SKILL.md is still the authority on its
process — this walks the seams between them: what you type, what comes back, and where you get
consulted.

This guide is project-agnostic. Substitute your own idea, bead IDs, and branch names —
nothing here is specific to any one codebase.

## 1. Starting Work

You describe an idea in plain language. That's the trigger for brainstorming — you don't
invoke it by name, just describe what you want:

> "I want to add rate limiting to the API — right now a bad client can hammer an endpoint with
> no backoff."

Brainstorming asks clarifying questions one at a time, proposes 2-3 approaches with trade-offs,
and presents a design in sections — approving each section as you go. When you approve, it
writes (or updates) a living design doc in `docs/designs/<topic>.md`, self-reviews it, asks you
to review it once more, then creates a bd **epic** decomposed into **feature**/**bug** children
— the epic's `--design` field carries the requirements, acceptance criteria, and trade-offs for
this change. It shows you the decomposition and asks if it looks right.

Once you approve the hierarchy, you say:

> "Plan it."

That hands off to writing-plans, which walks each feature/bug and creates **task** beads under
it — each one with the exact files to touch, the TDD steps, and code snippets, sized so a fresh
subagent with no other context could execute it. It self-reviews the whole hierarchy against the
spec before handing back to you: "Tasks created under epic `<epic-id>`. Moving to
subagent-driven execution."

## 2. The Execution Fork

Now you decide how the epic's tasks get built. The deciding question is dependency structure:

| Tasks... | Use | Shape |
|---|---|---|
| Build on each other (later tasks assume earlier ones' interfaces, files, or state) | subagent-driven-development | One branch, sequential dispatch |
| Are independent — no task's work depends on another's output | dispatching-parallel-agents | One worktree/branch per item, concurrent dispatch |

They compose: a planned epic's independent tasks can each be handed to a parallel-dispatch
batch, and inside each batch item, subagent-driven-development's task loop still governs how
that one item gets built.

**Sequential (single branch):** you say something like

> "Execute the spe-xyz plan."

subagent-driven-development claims the first task (`bd update <task-id> --claim`), dispatches a
fresh implementer subagent, and runs it through the loop: implementer builds and tests → task
reviewer checks spec compliance and code quality → if findings, a bounded fix loop (resume the
implementer, up to 5 rounds, escalating one step up the implementer agent ladder on rounds 4-5)
→ task bead closes with the commit
range as its reason. It repeats for every task in the feature, closes the feature, moves to the
next feature, and so on until the epic is done — then runs one whole-branch review before
declaring the branch review-clean. It does not check in between tasks; the only reasons it stops
are a BLOCKED status it can't resolve, a genuine ambiguity, or the epic being done.

**Parallel (many branches):** you say something like

> "Work through the ready beads." / "These 4 bugs are independent — knock them out."

dispatching-parallel-agents groups entangled items (ones that would touch the same files) into
one branch each, gives everything else its own worktree/branch, and dispatches implementers
concurrently — one subagent call per branch, all in the same response. Each branch then gets the
same per-branch review discipline as a single SDD task: a task review with a fix loop, plus a
security pass (combined across the batch, or per-branch, depending on batch size). As each
branch goes review-clean, it's added to a running list rather than delivered immediately.

**How much to run at once:** default to 4-5 concurrent subagents when the backlog has that much
truly independent work — wall clock matters, and medium effort keeps the burn rate manageable at
that width. Throttle toward ~3 when usage-cap headroom is tight: mid-window on a long run, or
when running at high effort. True concurrency is bounded by independent bead families —
implementers must never share files, so entangled work collapses into fewer, larger branches
regardless of how many you'd like to run. Parallelism front-loads token burn rather than
reducing it: running 5 branches at once spends roughly 5x the tokens over a shorter wall-clock
window, so a mid-flight cap exhaustion kills that many in-progress agents at once. They're
recoverable from their worktrees, but resuming them costs tokens and attention on top of what
was already spent.

## 3. Effort & Model Tiers

Every dispatch — implementer, reviewer, or delivery agent — runs at some combination of model
and reasoning effort. Most of the roster doesn't choose; it inherits your session's settings.
Only a handful of roles are pinned away from that baseline, and only because their work profile
warrants it.

**Session baseline:** your session runs at `effortLevel=medium` unless you've changed it. Set it
via the `/effort` slider (interactive), the `effortLevel` key in `settings.json`
(`low|medium|high|xhigh`), the `--effort` CLI flag, or the `CLAUDE_CODE_EFFORT_LEVEL`
environment variable — **not** `/config`, which doesn't carry this setting. Any dispatch that
doesn't pin its own effort runs at whatever your session is currently set to.

**Agent pins:** a subagent's frontmatter can set `effort: low|medium|high|xhigh|max`, which
overrides the session level for that agent regardless of what you're running at. Pins exist only
where a role's work profile diverges from the medium baseline:

| Agent | Model | Effort | Why |
|---|---|---|---|
| `implementer-mechanical` | haiku | low | Clear spec, 1-2 files, plan provides code snippets — transcription plus testing. |
| `implementer` | sonnet | medium | Default tier: multi-file coordination, message passing, pattern matching. |
| `implementer-complex` | opus | high | Design judgment, broad codebase understanding — also the SDD round-4/5 escalation target. |
| `pr-merger` | haiku | low | Mechanical `gh` operations: squash merge, pull main, verify CI. |
| `coderabbit-reviewer` | sonnet | low | Evaluate and apply a fixed suggestion list. |
| `branch-shepherd` | sonnet | medium | Delivery-tail orchestration: CI fix loop, conflict reconciliation, sequencing a branch train. |
| `adjudicator` | fable | high | One-shot ruling on an escalated question — dispatched with clean context, edits nothing. |

Everything else — task reviewers, the final whole-branch reviewer, the controller loop itself —
runs at the session baseline unless you've raised it for a specific run.

**Model tiers by phase** (from `docs/decisions/orchestration-model-tiering.md`): design-side work
— brainstorming, roadmap discussion, plan authoring against real code — runs on Fable, because a
subtly wrong plan costs more downstream than top-tier reasoning costs upfront. The controller
loop (dispatch, review, close, roll up) runs on opus — well within its territory, and running
coordination on Fable mostly buys more expensive bookkeeping. The implementer roster tops out at
opus; Fable is not an implementer tier, and the round-4/5 escalation ladder never reaches it.
The one place Fable participates in execution is a one-shot adjudicator, dispatched with clean
context (never as a fork — a fork inherits the full session and gets expensive fast) on
structural triggers only: a fix-loop breaker, a finding-vs-design conflict, an
implementer/reviewer factual contradiction, or a Critical finding touching data loss, security,
or user files. Structural triggers keep these dispatches rare and well-scoped — "this feels
hard" is exactly the judgment a mid-tier model can't make about itself, so the trigger has to be
structural, not a vibe.

**Sizing philosophy:** the norm is decomposing tasks (writing-plans) down to sonnet/haiku
granularity — most implementation work is mechanical once the plan carries the code to write.
`implementer-complex` (opus/high) is the escape valve for tasks that stay irreducibly
judgment-heavy even after good decomposition, not a default. The 2026-08 spe autonomous run is
the evidence for this split: undo/session semantics, WinAnsi encoding, and canvas geometry each
needed opus despite a well-decomposed plan.

A Claude 5 note: medium effort is roughly comparable to previous-generation high for
well-specified work, which is part of why medium is the baseline rather than high. Keep effort
high where long-horizon judgment matters, not as a default hedge.

The empirical guardrail is fix-round rate: if a role running at a lowered tier starts needing
more review or fix rounds than it used to, raise the tier back. That rate is the signal that the
tier was cut too far — not a hunch, not a preference.

## 4. Delivery

Whichever fork produced it, a review-clean branch goes to **branch-shepherd** — one branch from
an SDD run, or the accumulated train from a parallel batch. You dispatch it once, in the
background, and it runs the whole tail unattended, per branch, in order:

push → open PR (conventional-commit title, brief summary) → wait for CI → if CI fails,
investigate root cause, fix, push, re-wait (bounded at 3 attempts before it marks that branch
BLOCKED and moves to the next one in the train) → evaluate CodeRabbit's comments, auto-apply
sound fixes, reply with rejections where warranted → if main moved and the PR goes
CONFLICTING, merge main into the branch, resolve conflicts preserving both sides, run the suite,
push, re-wait → squash-merge with no body, delete the branch, pull main, verify CI on the merge
commit, remove the worktree → advance to the next branch in the train (re-checking its mergeable
state first, in case the merge you just did made it CONFLICTING).

It reports back **once**, at the end: one outcome table — merged SHA, or BLOCKED with the
reason, per branch — plus any escalations.

**You get consulted for:**
- A **BLOCKED** branch — 3 CI fix attempts exhausted, or a conflict it couldn't resolve safely.
- A **design-level CodeRabbit suggestion** — branch-shepherd escalates rather than guessing;
  it never replies to an escalated comment.
- A **plan contradiction** surfaced during execution (a finding that conflicts with what a
  task's design mandates) — the controller asks which governs, it doesn't decide alone.
- **Decision-record classification** — record-decision asks whether a choice is an ADR
  (architecture, language/framework, testing strategy, CI/CD design) or a decision doc (tool
  choice, naming, config, pre-commit setup) whenever it's uncertain.

## 5. What You See During an Autonomous Run

This mirrors Joe's own `~/.claude/CLAUDE.md` "Autonomous runs" section — read that as the
canonical statement; this is how it plays out inside these skills.

Narration is terse: at most one short line between actions. Orchestrator context gets re-read
every turn, so verbose statuses aren't free color commentary — they're a recurring tax that adds
up over a long run (a major driver of cap exhaustion in the 2026-08 spe run). Durable state goes
in bd, git, or memory — never conversation prose:

- **bd** is the durable record — task status, fix-round notes, close reasons, and anything
  worth remembering across a compaction (`bd remember`). Conversation memory does not survive
  compaction; bd does.
- **Discovered work** gets filed as a bead (`bd create ... --deps discovered-from:<task-id>`),
  never silently dropped.

Substantive prose is reserved for two things: decisions you need to make, and judgment calls
made on your behalf that you should be able to audit — the "Questions that stop the line" and
"Everything else" split below is that reservation in practice.

**End-of-run summary:** when a run finishes, you get one summary, not a narration trail —
a brief recap of the work done (short bullets, not branch-by-branch or PR-by-PR narration),
then decisions made, judgment calls with rationale, deviations from the plan, and anything that
wouldn't be visible from `git log --oneline` alone (rulings, rejected approaches, deferred
work). branch-shepherd's one outcome table (§4, above) is this shape applied to delivery.

**Checking progress from cold** — a fresh session, or after a compaction:

```bash
bd ready              # What's available to claim right now
bd show <id>          # Full detail on one issue: status, notes, fix-round history
git log --oneline      # What's actually landed, independent of bd's bookkeeping
gh pr list             # What's open, and its CI/mergeable state
```

**Questions that stop the line** — the run does not proceed past these without you:

- "This finding conflicts with what the task's design mandates — which governs?"
- "Should I record this as an ADR or decision doc?"
- "A load-bearing finding survived the fix-round cap — reporting BLOCKED with the finding, the
  task text it collides with, and the fix history."
- A pre-flight scan finds tasks that contradict each other or the epic's Global Constraints —
  batched into one question, asked before execution starts, not one interrupt per discovery.

Everything else — routine fix rounds, CodeRabbit apply/reject calls, scoped re-reviews — runs
without a check-in.

## 6. A Worked Example

> **You:** "Here's a bug list: the rate limiter double-counts retries, the health check
> endpoint times out under load, and the config loader ignores `.env.local`. They don't touch
> the same code."
>
> **System:** *(brainstorming, abbreviated for three small bugs)* creates a bug bead per item
> under a small epic; you approve the decomposition. "Tasks created — moving to execution."
>
> **You:** "These are independent — work through them in parallel."
>
> **System:** *(dispatching-parallel-agents)* three worktrees, three branches, three
> implementers dispatched concurrently. Each finishes, goes through its own task review + fix
> loop, then a security pass. All three land in the accumulated list: `fix/retry-double-count`,
> `fix/health-check-timeout`, `fix/env-local-config`.
>
> **You:** "Ship them."
>
> **System:** *(branch-shepherd, backgrounded)* — works the train: pushes and opens three PRs,
> waits out CI on each, applies two minor CodeRabbit suggestions and rejects one ("would
> reintroduce the race the fix removes"), squash-merges all three, cleans up the worktrees.
> Reports back:
>
> | Branch | Outcome | Escalations |
> |---|---|---|
> | `fix/retry-double-count` | merged `a1b2c3d` | none |
> | `fix/health-check-timeout` | merged `e4f5g6h` | none |
> | `fix/env-local-config` | merged `i7j8k9l` | none |

## See Also

- [`plugins/joe-bag-of-tricks/skills/`](../plugins/joe-bag-of-tricks/skills/) — the full skill
  reference; this guide is the walkthrough, each SKILL.md is the authority on its own process
- [`plugins/joe-bag-of-tricks/agents/branch-shepherd.md`](../plugins/joe-bag-of-tricks/agents/branch-shepherd.md)
- `docs/architecture.md` — where components live in this repo, if you're editing the toolkit
  itself rather than using it
