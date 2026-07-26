# Git Workflow Rules

## Feature Branches Only
Never commit directly to main. All changes go through feature branches and pull requests.
Branch naming: `feat/`, `fix/`, `docs/`, `chore/`, `refactor/` + short description.
Upstream syncs use `sync/upstream-vX.Y.Z`.

## Worktrees
For extensive changes, use git worktrees in project-local `.worktrees/` via the
`/joe-bag-of-tricks:using-git-worktrees` skill.

This is a **declared worktree preference** — the skill's consent prompt does not apply here.
Isolate without asking, and always use `.worktrees/`. Prefer a native worktree tool
(`EnterWorktree`) over `git worktree add` when one is available, per that skill's Step 1a.

## Merge Policy
- Squash-merge feature branches; delete the branch on merge.
- Upstream syncs squash-merge too. The fork shares no ancestry with upstream, so a sync is an
  ordinary branch — there's no merge commit to preserve. See docs/adr/002-no-remote-upstream-sync.md.

## Divergent Workflow
NEVER edit an upstream file to express a divergent workflow (e.g. beads). Replace the
component and record it in `docs/customizations.md`. See `@.claude/rules/upstream-sync.md`.

## Completing Work
When implementation is complete and validation passes, YOU MUST invoke the
`/joe-bag-of-tricks:finishing-a-development-branch` skill — it handles push/PR/CI then merge.

## Session Completion
PR-based workflow; never push directly to main. Work is complete only when the PR is open and
CI is green. PRs never merge without passing CI.
