# Trains Front-Load Every Push; Merges Stay Serial

## Decision

- **`branch-shepherd` pushes every branch in the train and opens every PR before any branch's
  CI wait.** CI and CodeRabbit run server-side and in parallel across PRs; their wall-clock cost
  ends at the last push that starts them, not at the last merge.
- **Everything that needs judgment stays strictly serial, in the planned merge order:** CI-failure
  fixes, review triage, conflict reconciliation, and the merge itself. Front-loading changes when
  the waits *start*, not what order branches *land*.
- **Merging never uses `--delete-branch`** (in `branch-shepherd` Step 7 and `pr-merger` Step 1
  alike). The flag bundles a local branch deletion ahead of worktree removal, and git refuses to
  delete a branch a worktree has checked out. Merge success is read from
  `gh pr view --json state,mergedAt`, never from gh's exit code; cleanup runs worktree removal,
  then `git branch -D`, then `git push origin --delete` (tolerating an already-gone remote ref).
- **A no-runs CI wait checks `mergeable` first.** A `CONFLICTING` PR has no merge ref, so
  GitHub can never fire its `pull_request` workflows — the fix is merging main into the branch,
  not waiting, and not close/reopen or an empty commit (both measured useless).
- **Post-merge verification stays per-merge by default.** The dispatch may specify train-level
  verification (PR gate per branch at merge time, one full Actions enumeration on main after the
  last merge) as a documented option; the default is unchanged.

## Rationale

Measured on the 2026-08-29/30 throwntom trains: ~21 minutes per PR, strictly serial (133 min for
5 branches, 133 for 5-of-6, 106 for 5), against a ~12.5-minute best case — while the long poles,
CI and CodeRabbit, are embarrassingly parallel across PRs. The serialization was self-inflicted:
each branch's push waited for the previous branch's merge, so servers sat idle in sequence.
Post-merge verification added ~4–5 min per PR (~20%), which motivates offering — not defaulting —
train-level verification: the trade is that a broken merge surfaces one train-tail later.

The merge-ordering half is bead `joe-bag-of-tricks-dxw` (GH #77): `--delete-branch` failed on
10 of 10 worktree-based merges (`fatal: ... is already used by worktree ...`), each one a PR that
GitHub had merged but the agent reported as a failed merge, because the verdict came from gh's
exit code. Local branch deletion must follow worktree removal; the flag makes that ordering
impossible, so the flag goes.

The `CONFLICTING` no-runs check comes from PR #121, which sat 18 minutes with zero CI runs:
without a merge ref there is nothing for `pull_request` workflows to run against. Close/reopen
and empty commits were tried and did nothing; merging main fixed it immediately.

## Cost

More conflict reconciliation. With the whole train pushed against the same main, every merge can
make later branches `CONFLICTING`, where serial pushing let each branch start from moved main.
That work was accepted knowingly: reconciliation was already in the loop (Steps 6/8), it is
minutes against the tens of minutes serialization cost, and a reconciliation that changes
anything substantive re-runs the branch's gates — suite and review handling on the new head —
not just its CI, so the parallelism does not dilute the review bar.
