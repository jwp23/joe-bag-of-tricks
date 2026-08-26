# SDD May Overlap a Task's Review With the Next Task's Implementation

## Decision

`subagent-driven-development`'s task loop stays serial by default, with one bounded exception.
Once task N's implementer has reported DONE and N's reviewer is dispatched, the controller may
claim and dispatch task N+1 without waiting for N's review, when **both** hold:

- N+1 is a mechanical dispatch — its brief carries the code it needs — and
- N's review is expected clean: N was itself mechanical **and** its implementer returned plain
  DONE.

Overlap is forbidden when N went to `implementer-complex`, when N returned DONE_WITH_CONCERNS /
BLOCKED / NEEDS_CONTEXT, or when N is already in a fix round.

Three invariants hold the exception in place:

- **Single writer.** The overlap is review-against-implement, never implement-against-implement.
  Exactly one implementer writes to the worktree at a time, unchanged from before.
- **The moving base is recorded.** `bd note <N+1-id> "Overlap: dispatched while <N-id>'s review
  was open — base included unreviewed work"`, written before the dispatch, not after.
- **Findings collapse the overlap.** The moment N's review returns a finding, N+1 is the last
  task dispatched until N's loop is clean.

**A fix round for N never rebases.** It waits for N+1's implementer to report, then lands as
ordinary commits on top of N+1's. Its scoped re-review takes `FIX_BASE` = the HEAD recorded
immediately before the fix dispatch.

## Rationale

Measured over a 9-task run (throwntom epic `throwntom-s9z`, plugin v1.8.1, ~75 min wall clock),
roughly 25% of wall clock was the controller idle against reviews of mechanical tasks — reviews
that came back clean 5 times out of 6. That is the only dead time in the loop that costs nothing
to reclaim: the controller is doing no work, and no other agent is blocked on it.

The two conditions are deliberately mechanical rather than judgment calls. "This review will
probably be clean" is not one of them — the controller cannot see what it is missing, which is
the same reasoning the Escalation triggers rest on. Tier and reported status are both checkable
by looking, so the gate cannot be talked past.

**Rebasing was considered and rejected**, though the originating issue (#56) proposed it. Rewriting
history under a live implementer that holds the worktree is the failure this plugin already guards
against elsewhere, and it is unnecessary: because exactly one implementer writes at a time, N's fix
commits are always the tail of history when they land. Re-scoping `FIX_BASE` to the pre-fix HEAD
gets the same clean re-review diff with no history rewrite at all. Without that re-scoping the
naive `FIX_BASE` — the head the first review saw — would put N+1's entire diff in front of a
re-reviewer scoped to N's findings.

**True parallelism across worktrees stays rejected.** SDD assumes one linear branch and a
single-writer worktree; rebases, bd dependency reshaping, and merge ordering outweigh the gain for
a typical epic. This decision does not open that door — it only reclaims controller idle time.

## Cost if wrong

N+1 builds on code N's review has not cleared. Bounded by the two conditions: both tasks are
mechanical, N's implementer raised nothing, and a finding stops any further dispatch immediately.
The realistic bad case is one extra fix round applied over N+1's commits — which the FIX_BASE rule
already handles — not a corrupted branch.

## Validation

The originating measurement is the throwntom run above, recorded in GitHub issue #56. The rule's
guards were authored against `docs/decisions/sdd-rulings-not-stalls.md` (the controller rules and
records rather than stalling) and the single-writer invariant already stated in the skill's
dispatch section.

The wall-clock claim itself is not re-measured here; per `docs/adr/006-defer-behavioral-evals.md`
this repo has no standing harness for multi-task orchestration timing, and one epic is the
available evidence. Treat 25% as the observed figure from one run, not a validated average.
