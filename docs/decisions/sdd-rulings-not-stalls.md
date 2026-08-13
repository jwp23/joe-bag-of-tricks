# SDD: Rulings, Not Stalls

## Decision

Adopted upstream superpowers v6.3.0's autonomy model in `subagent-driven-development`: a running
plan does not park itself waiting on a human. Conflicts, ambiguities, plan defects, and
plan-mandated findings are decided by the controller, each decision recorded as a
`bd note ... "Ruling: <what> — <why> — <cost if wrong>"` and collected exhaustively into a
"Rulings I made" roll-up in the final message at Finish. The former ask-human routes
(design-conflict "ask which governs", breaker "STOP: report BLOCKED") are gone. Only four
things stop a run: an irreversible/destructive operation, a security-sensitive action, a
side effect outside the worktree that norms say you ask about first (merge, push to shared
branch, publish), or a plan so broken every path forward is a guess.

Reconciled with the fork's pre-existing adjudicator escalation (2026-08-09): the structural
triggers and one-shot top-tier adjudicator dispatch stay — the adjudicator is now *how* a
mid-tier controller makes a ruling without stalling, not a substitute for asking. Its ruling
stands, is recorded as a `bd note`, and surfaces in the Finish roll-up. The v6.2.0-era
precedence clause ("when your human partner is reachable, design/plan conflicts remain THEIR
call") was removed as incompatible with the model.

## Rationale

- Upstream's argument, adopted: a wrong ruling costs rework the human can see and undo; a
  session parked on a question costs their whole day and buys nothing. The spec (epic
  description/design + the `--spec-id` living design doc) is the binding authority to rule
  against, so rulings are grounded, not guesses.
- Matches the maintainer's standing "Autonomous runs" instructions: judgment calls made on
  their behalf are expected, provided they are recorded with rationale and surfaced in the
  end-of-run summary — which is exactly what the `Ruling:` note convention plus the Finish
  roll-up mechanize.
- The fork keeps what upstream lacks: the adjudicator gives the ruling a top-tier reasoning
  seat on structural triggers, instead of trusting a mid-tier controller's self-assessment.
- Cost if wrong: an autonomous run can now build several tasks on a bad ruling before the
  human sees it. Mitigations: rulings carry "what it costs if wrong", every dependent
  dispatch carries the ruling, and the four stop classes still halt anything irreversible.

Ratified by the maintainer (2026-08-13) with one condition, now in the skill: design/plan-conflict
rulings must lead the "Rulings I made" roll-up, individually flagged with the finding, the plan
text they collided with, and which was ruled to govern — the end-of-run summary is where the
human partner understands the shift and directs changes.
