# The Adjudicator Is a Shared Agent, Not an SDD-Local Section

## Decision

- **Escalation does not depend on the controller's own tier.** The deterministic triggers
  apply to any orchestrator dispatching subagents, including one already running on the top
  tier. `subagent-driven-development`'s framing of the mechanism as "how a MID-TIER controller
  rules without stalling" is removed.
- **The adjudicator becomes a fork-original agent**, `agents/adjudicator.md`, pinning
  `model: fable`. The agent definition is the single statement of the dispatch contract —
  clean context, the artifact file paths, one narrow question naming every fired trigger, and
  a ruling recorded as a `bd note`. Both skills dispatch it by name and neither restates it.
- **Each skill owns its own trigger list.** The triggers are phrased in the vocabulary of the
  path that fires them, so `dispatching-parallel-agents` gets the parallel/bead-crunch
  analogues rather than a copy of the SDD four.
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
  diff-merged skill to a hand-ported one across syncs.
- Preserved properties, unchanged from the SDD-local version: escalation is a **dispatch, never
  a main-loop model switch**; several triggers firing at once is still ONE dispatch carrying one
  question packet; the ruling is recorded as a `bd note` so it is audited after the run, not
  during; and the adjudicator is never dispatched as a fork, because a fork inherits the full
  session context.
- Cost if wrong: a second escalation surface means more Fable dispatches on the parallel path,
  each with real cost. Bounded by the same discipline that bounds the SDD side — triggers are
  structural and mechanically detectable, so they fire rarely and never on a hunch.

## Supersedes

Amends `orchestration-model-tiering.md`, whose rationale attributes escalation to what "a
mid-tier model cannot make about itself" and whose Decision section scopes adjudication to
"the SDD skill." Both now read as tier-independent and cover the parallel path. That doc's
other rulings — implementers cap at opus, Fable is the adjudicator tier, Fable owns the
design-side phases — stand unchanged.
