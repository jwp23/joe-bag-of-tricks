# The Adjudicator Is a Shared Agent, Not an SDD-Local Section

## Decision

- **Escalation does not depend on the controller's own tier.** The deterministic triggers
  apply to any orchestrator dispatching subagents, including one already running on the top
  tier. `subagent-driven-development`'s framing of the mechanism as "how a MID-TIER controller
  rules without stalling" is removed.
- **The adjudicator becomes a fork-original agent**, `agents/adjudicator.md`, pinning
  `model: fable`. The contract splits by side. The agent definition states the agent-side
  half — what it reads, the RULING / WHY / COST IF WRONG shape it returns, and its bounds.
  The skills state the orchestrator-side half — clean context, the artifact and decision
  paths, one narrow question naming every fired trigger, and the ruling recorded as a
  `bd note`. Both skills dispatch the agent by name; neither side restates the other.
- **One shared trigger set, not one per skill.** The four triggers are path-independent.
  `subagent-driven-development` states them; `dispatching-parallel-agents` cross-references
  that statement by namespace, as it already does for SDD's Task Loop. They live in the skills
  rather than in the agent definition because the orchestrator never reads an agent's body —
  it sees only the roster's name, description, and tool list, so triggers placed in the agent
  would be invisible to the party that fires them. The agent definition carries the agent-side
  contract, which is the subagent's own operating instruction. Only the fix-loop bound in
  trigger 3 is counted per path — SDD counts fix rounds, the parallel path counts repeated gate failures on
  one branch — so each skill states its own count and nothing else.
- **Trigger 2 is bounded by a named list.** "An agent's output conflicts with a governing
  decision" is checked against the decision docs the orchestrator names up front in the batch
  setup or in each dispatch it composes, plus any recorded during the run — not against all of
  `docs/adr/` and `docs/decisions/`. The same list goes into the task reviewer's
  global-constraints block, which is what performs the comparison. The adjudicator dispatch
  carries those paths so it reads the decision itself rather than the orchestrator's
  paraphrase.
- **Scope is the two orchestration skills.** `executing-plans` and the shepherding agents are
  out of scope; they do not fan out independent work and produce no cross-agent conflicts.
- **Extends the joe-bag-of-tricks-p5x ruling.** That ruling gave agent definitions to
  implementers only and kept reviewers on raw-model dispatch. The adjudicator joins the
  implementers on the agent side of that line: it has one fixed model, one fixed contract, and
  no per-dispatch variation, which is what an agent definition encodes. Reviewers stay
  raw-model because their tier is chosen per diff.

## Rationale

- The stated reason for deterministic triggers has always been that *a model cannot reliably
  see what it is missing*. That is a property of models, not of tiers — an opus orchestrator
  self-assessing "I can settle this one" is the exact failure mode the trigger list was
  written to prevent. Scoping the mechanism to mid-tier controllers left the premise
  contradicting its own conclusion.
- The parallel-dispatch path is the one that fans out the most independent work, so it produces
  the most cross-agent contradictions, yet it had no escalation concept at all — zero mentions
  of adjudication, escalation, or model tiers. Observed in the 2026-08-14 bead crunch (11
  branches, 15 agents): at least two trigger-shaped situations were settled ad hoc by the
  orchestrator in prose, with no ruling recorded and therefore nothing for the maintainer to
  audit afterward.
- An agent definition enforces "stated once" mechanically. The two rejected alternatives —
  a shared skill mirroring `implementer-contract`, or a plain shared markdown file — both leave
  the contract enforced only by discipline. The skill option additionally spends roughly 77 of
  the 423 remaining always-loaded budget tokens (measured 2026-08-14) on a skill that nothing
  preloads: `implementer-contract` earns its slot through `skills:` frontmatter preloading into
  agents, and no such mechanism applies here — two SKILL.md bodies linking to it get the same
  result from a file. The shared-file option would have made `dispatching-parallel-agents`
  (`patched`) point into `subagent-driven-development`'s directory (`replaced`), coupling a
  diff-merged skill to a hand-ported one across syncs. The trigger cross-reference adopted
  instead is a namespace reference in prose, not a path into another skill's files, and that
  skill already cross-references SDD's Task Loop the same way.
- Preserved properties, unchanged from the SDD-local version: escalation is a **dispatch, never
  a main-loop model switch**; several triggers firing at once is still ONE dispatch carrying one
  question packet; the ruling is recorded as a `bd note` so it is audited after the run, not
  during; and the adjudicator is never dispatched as a fork, because a fork inherits the full
  session context.
- **Trigger 2 is deliberately the weakest of the four, and known to be.** The others are
  detected by counting or by comparing two reports; this one asks whether work violates a
  recorded decision, which a model can silently fail to notice — the same self-assessment
  failure the triggers exist to avoid. Naming the governing decisions up front moves that
  judgment to batch setup, where it is made once, in the open, and is visible in the dispatch.
  A decision nobody thought to name can still be violated silently; that hole is accepted, not
  closed. It is kept despite the weakness because the catch is high-value: an agent adding
  backward compatibility, or editing an upstream `replaced` file to express a divergent
  workflow, violates a standing decision that no review finding is guaranteed to surface.
  Note that SDD's shipped finding-vs-design trigger is *not* evidence for this one — it has
  never fired in a recorded run and is equally unvalidated.
- Cost if wrong: a second escalation surface means more Fable dispatches on the parallel path,
  each with real cost. Bounded by the same discipline that bounds the SDD side — triggers are
  structural and mechanically detectable, so they fire rarely and never on a hunch.

## Supersedes

Amends `orchestration-model-tiering.md`, whose rationale attributes escalation to what "a
mid-tier model cannot make about itself" and whose Decision section scopes adjudication to
"the SDD skill." Both now read as tier-independent and cover the parallel path. That doc's
other rulings — implementers cap at opus, Fable is the adjudicator tier, Fable owns the
design-side phases — stand unchanged.
