# Orchestration Model Tiering: Opus Controller, Fable Adjudicator, Opus-Capped Implementers

## Decision

- **Implementer roster tops out at opus.** The `implementer-mechanical` (haiku) /
  `implementer` (sonnet) / `implementer-complex` (opus) trio from
  joe-bag-of-tricks-ufn stands as specified. Fable is not an implementer tier,
  and the rounds-4-5 / BLOCKED escalation ladders do not reach it.
- **The controller loop runs on opus.** Dispatch, review, close, roll up is
  mid-tier work; running it on the top tier mostly buys more expensive
  bookkeeping.
- **Fable is the adjudicator tier.** The occasional controller-level decisions
  that benefit from top-tier reasoning are exactly the ones the SDD skill routes
  to the one-shot adjudicator on structural triggers (fix-loop breaker,
  finding-vs-design conflict, implementer/reviewer factual contradiction,
  Critical finding touching data loss/security/user files). Those dispatches pin
  Fable. The skill's "`model: "opus"` or above if available" phrasing becomes an
  explicit Fable pin when joe-bag-of-tricks-p5x converts dispatches to agent
  types.
- **Fable also owns the design-side phases**: brainstorming, roadmap discussion,
  and plan authoring against real code — a subtly wrong plan costs more
  downstream than top-tier reasoning costs upfront.

## Rationale

- Origin: the 2026-08 spe autonomous run. Post-run analysis found the
  coordination role (dispatch, adjudicate, close beads) was well within opus
  territory, while Fable earned its cost exactly at the judgment calls — design
  catches during plan authoring and adjudication rulings (e.g. the strip-on-open
  render bug caught at plan time, the fingerprint-scope finding ruling).
- Escalation is a **dispatch, never a model switch**: an autonomous opus
  controller fires a one-shot Fable adjudicator with clean context, the artifact
  file paths, and one narrow question — on structural triggers only, because
  "this feels hard" is precisely the judgment a mid-tier model cannot make about
  itself. Rulings land as `bd note`s so Joe can audit every judgment call after
  a run.
- Structural triggers keep Fable dispatches rare and well-scoped. Extending the
  implementer ladder to Fable would instead make it the default escalation for
  every stuck task, defeating the tiering. Opus implementers sufficed in
  practice (spe run: undo semantics, WinAnsi encoding, canvas geometry).
- Residual risk: a decision that is both subtle and fires no trigger. Bounded —
  same class as any reviewer miss; the final whole-branch review on the top tier
  is the backstop.
- Never dispatch the adjudicator as a fork: a fork inherits the full session
  context (a 249k-token fix dispatch in the spe run was the session's worst
  cost by an order of magnitude). Clean-context dispatch only.
- Decided by Joe, 2026-08-14, confirming the spe-session design conversation.
