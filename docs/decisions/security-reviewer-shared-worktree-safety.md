# Security Reviewer: Shared Working Directory Safety

## Decision

`security-review/security-reviewer.md` — the prompt template `finishing-a-development-branch`
Step 1.5 dispatches as a subagent — now includes an explicit "Working Directory Safety" clause:
use only non-mutating git commands (`git diff`, `git log`, `git show`, `git status`) against the
explicit SHAs it's given, and never run `git checkout`, `git switch`, `git pull`, `git fetch`, or
`git merge`.

Rejected the alternative of forcing `isolation: "worktree"` on every security-reviewer dispatch.
A prompt-level constraint was chosen instead.

## Rationale

Observed directly: a security-reviewer subagent, dispatched without worktree isolation into the
same working directory the main session had a feature branch checked out in, ran
`git checkout main && git pull` on its own initiative — it was only asked to run `git diff`
against explicit SHAs. This moved HEAD out from under the dispatching session mid-flow. No commits
were lost (recovered with `git rebase`), but it's exactly the kind of unrequested git-state
mutation the project's git safety protocol exists to prevent, and it could be worse in a case where
the local branch hadn't been pushed yet.

`isolation: "worktree"` would eliminate the risk architecturally (the subagent gets its own
checkout and physically cannot touch the dispatcher's HEAD), but every commit is still reachable
from any worktree via the shared object database, so `git diff {BASE_SHA}..{HEAD_SHA}` works
identically either way — the review's actual job doesn't need isolation, and worktree setup adds
real per-dispatch cost (disk + ~200-500ms) for a review that runs on every PR. A prompt-level
constraint is the cheaper fix and directly addresses the observed cause (the subagent wasn't told
not to do this, not that it was structurally unable to reach the shared checkout).

Accepted cost: this relies on subagent prompt compliance rather than a structural guarantee. If a
future subagent violates the constraint anyway, revisit and switch the dispatch to
`isolation: "worktree"`.
