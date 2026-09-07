# Mechanical-Tier Reviewer May Apply Trivial Fixes Directly

## Decision

- For SDD tasks implemented by the **mechanical** tier (`implementer-mechanical`)
  only, the task reviewer may apply trivial wording/doc-accuracy fixes directly
  instead of round-tripping the finding back through the implementer for a fix
  dispatch.
- **Standard and complex tiers are unchanged**: the reviewer only finds, the
  implementer only fixes, full multi-round cycle intact. The full loop caught a
  Critical ADR-010 race on a complex task in the throwntom bead-crunch session
  23b7fc9d — do not thin review depth there.
- This is a deliberate, scoped exception to SDD's general finder/fixer role
  separation (`subagent-driven-development/SKILL.md` ~394-395: implementers are
  "not helpers, and never a reviewer" — review arrives from the controller, after
  the report). The exception is bounded to one tier; it does not relax the
  principle elsewhere.

## Rationale

- Measured on throwntom bead-crunch session 23b7fc9d: bxd.19, a one-paragraph
  docs-pointer fix on the mechanical tier, consumed six agent dispatches
  (implement, review, fix, re-review, fix, re-review round 2) because the
  reviewer kept finding comment-wording inaccuracies and the fix loop cycled at
  full weight — several dollars and ~5 orchestrator notifications for a trivial
  change.
- Mechanical-tier tasks are, by definition, transcription-grade: the plan already
  contains the code/text to write. A wording nit on that tier carries none of the
  judgment risk that role separation exists to guard against on standard/complex
  tasks, so collapsing finder/fixer there for trivial fixes trades a real but
  small risk (a reviewer's own edit going unreviewed) for eliminating a
  multi-dispatch loop on work that was never going to need one.
- Ruled by Joe 2026-09-07 while triaging open design questions in epic
  `joe-bag-of-tricks-s31` (token-efficiency findings from the 23b7fc9d audit), for
  bead `joe-bag-of-tricks-hvq`.
- Implementation of the mechanical-tier review path itself is tracked in
  `joe-bag-of-tricks-hvq`; this doc records the ruling, not the resulting
  SKILL.md text.
