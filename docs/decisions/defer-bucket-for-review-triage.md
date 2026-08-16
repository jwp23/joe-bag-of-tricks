# Review Triage Gets a DEFER Bucket, and It Files the Issue Itself

## Decision

- **Triage is two-axis.** `coderabbit-reviewer` and `branch-shepherd` answer two independent
  questions about every review finding: is it **correct**, and separately, is it **in scope for
  this branch**. The pair picks the bucket — correct + in scope is APPLY, correct + out of scope
  is **DEFER**, incorrect is REJECT regardless of scope.
- **REJECT now means only "the finding is wrong."** Its four criteria (less maintainable,
  technically incorrect, off-convention, needless complexity) are all statements about
  correctness, so "right, but not this PR's job" never belonged there.
- **DEFER files an issue in the project's tracker before the PR merges**, then replies on the
  comment thread with the issue ID. The body carries: the source PR, that the finding was
  confirmed by reading the code, whether it is pre-existing (naming the merge-base SHA), and a
  fix direction. Both agents grew a **Deferred** section in their report format.
- **`branch-shepherd`'s "never run `bd` or any other issue-tracker command" rule narrows to one
  carve-out**: creating a deferred-finding issue. It still may not update, close, or otherwise
  mutate an existing tracker item.
- **A failed tracker write never blocks the merge** (Joe's ruling, 2026-08-15). The agent replies
  on the thread with the finding restated in full, reports it as `UNFILED` with the reason, and
  continues. In `branch-shepherd`'s outcome table that is a loud line, never a BLOCKED branch.
- **A reviewer withdrawing a finding after a scope reply is not invalidation.** Conceding the
  scope argument says nothing about whether the code is correct; the finding is still deferred.
- **DEFER requires an affirmative correctness judgment.** Axis 1 is answered first, and a finding
  that fails it never reaches the scope question. Deferring a finding you have not confirmed by
  reading the code is forbidden — it moves unreviewed noise into the tracker instead of triaging
  it. Unsure resolves to REJECT or ESCALATE, never to DEFER.
- **Tracker-agnostic wording throughout** — "the project's issue tracker", discovered from
  CLAUDE.md in each agent's Step 1, never `bd create`. These agents ship to projects that do not
  use beads.

## Rationale

The three-bucket split had no home for a true finding that doesn't belong in the current PR. Such
a finding either got force-applied against the branch's scope, or landed in REJECT and was
answered with a bare "Keeping as-is" — which closes the thread, looks resolved, and leaves no
record anywhere. The automation was silently discarding correct findings.

The motivating case is jwp23/spe PR #155: CodeRabbit raised two valid Major findings, both
correctly declined as out of scope for a tests-only PR. One was filed by hand; the other
(`probe_command` ignoring exit status) surfaced only days later in an audit. CodeRabbit had even
offered to open a follow-up issue, and the offer went unanswered.

Filing directly, rather than reporting the deferral up to the caller for filing, is what makes
this survive: a report line is exactly the kind of record that gets skimmed past at the end of an
unattended branch train, which is the failure mode being fixed. That is why `branch-shepherd`'s
tracker prohibition bends here rather than the deferral bending into a report. The prohibition's
purpose — keep an autonomous delivery agent out of the tracker's workflow state — is preserved by
allowing only creates.

Blocking a merge on a failed tracker write was considered and rejected. A tracker outage is not a
code-quality signal, and blocking on one trains us to bypass the mechanism. The `UNFILED` path
keeps the finding durable in the PR thread, which is the record that survives regardless.

## Validation

Pressure-tested with subagents on a throwaway fixture — a genuine tests-only branch whose
`probe.sh` bug is present at the merge base, so the scope question has a checkable answer. Three
findings (out-of-scope-but-correct, wrong, in-scope-and-correct), under stacked pressure: release
cut in 40 minutes, three branches queued, 12-minute CI restart per push, and the reviewer having
*withdrawn* the Major finding after the author argued scope. Both agents run at their pinned
sonnet tier.

**Baseline (old bodies) failed in both directions.** `coderabbit-reviewer` rejected the withdrawn
Major as "moot," and rejected the second finding while naming the missing bucket in its own reply
— "worth a follow-up ticket with tests, not a same-PR patch." `branch-shepherd` took no action at
all on the withdrawn finding ("not this shepherd's call") and *force-applied* an out-of-scope
change to `probe.sh` on a tests-only branch. Both documented failure modes reproduced.

**With the new bodies, 3/3 runs deferred it**, ran the real `git diff <merge-base>..HEAD` rather
than guessing at scope, and refused to read the withdrawal as invalidation. The no-tracker variant
returned `DONE` with `UNFILED` and the finding restated in full on the thread — never blocked.

The correctness-judgment rule above came out of that run: every agent deferred a finding it had
not established was correct, one of them while voicing doubt about it. Deferring is cheaper than
judging, so the bucket needed an explicit floor.

Isolating that rule took three fixture attempts, and the two failures are the useful part: a
finding that is *poor advice* is not a finding that is *wrong*, and agents defer the first quite
reasonably. Only a finding whose premise is checkably false about the code — here, one describing
a `REPORT_DIR` assignment on line 11 of a 9-line file — creates a condition where DEFER is
unambiguously the wrong bucket.

Against that finding both agents **rejected**, disproving the premise by reading the file, and one
stated the ordering explicitly: "Reject on axis 1 (finding is incorrect); scope was never reached."
Across all four post-refactor runs the out-of-scope bug still defers and the in-scope nit still
applies, so the floor costs nothing that 4po cares about.
