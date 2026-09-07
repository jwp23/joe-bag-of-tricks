# Batch-Dispatch Report Contract Points at implementer-contract

## Decision

- The batch-dispatch brief in `dispatching-parallel-agents/SKILL.md` points at
  the existing `implementer-contract` skill for its report-contract fields (gate
  results with exact commands, what could not be verified, whether each ticket's
  stated premise held, anything fixed that no ticket mentioned) rather than
  naming those fields a second time locally.
- Consequence, accepted deliberately: `implementer-contract` is preloaded into
  `implementer-mechanical`, `implementer`, and `implementer-complex` via `skills:`
  frontmatter (see [[implementer-contract-as-preloaded-skill]]). Any future edit
  to `implementer-contract` now also changes SDD implementer behavior, not just
  ad-hoc batch-crunch dispatches. There is one contract to keep in sync instead
  of two.

## Rationale

- A parallel bead crunch dispatches general agents, not SDD's implementer tiers,
  so those dispatches inherited no report contract — every report was shaped by
  whatever RETURN: block the orchestrator improvised that session. Observed
  across ~19 batch dispatches / ~28 PRs (GitHub issue #90): reports varied too
  much to compare or skim ("all gates green" vs. exact commands run), and each
  brief burned 60-100 near-identical words restating a contract that already
  existed in `implementer-contract`.
- The alternative — naming the fields a second time in
  `dispatching-parallel-agents/SKILL.md` — keeps the two mechanisms independent
  (editing one never silently changes the other) but reintroduces exactly the
  duplication `implementer-contract` was created to eliminate
  ([[implementer-contract-as-preloaded-skill]]: "four near-identical copies…
  guarded only by an 'edit them together' clause"). One contract, deliberately
  shared, was judged the better trade.
- Ruled by Joe 2026-09-07 while triaging open design questions in epic
  `joe-bag-of-tricks-s31` (token-efficiency findings from the 23b7fc9d audit), for
  bead `joe-bag-of-tricks-3yo`.
- Implementation is tracked in `joe-bag-of-tricks-3yo`; this doc records the
  ruling, not the resulting SKILL.md text. The exact-command gate-evidence
  requirement must survive the edit — related bead `joe-bag-of-tricks-y5r` needs
  the same terseness without reintroducing "all green" summaries.
