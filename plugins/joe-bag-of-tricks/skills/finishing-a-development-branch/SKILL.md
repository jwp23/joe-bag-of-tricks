---
name: finishing-a-development-branch
description: Use when implementation is complete and all tests pass - handles the push, PR creation, and CI verification workflow
---

# Finishing a Development Branch

## Overview

Complete development work by pushing the feature branch, creating a PR, and waiting for CI to pass.

**Core principle:** Verify tests -> Push -> PR -> Wait for CI -> Handle CodeRabbit reviews -> Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before proceeding, verify tests pass:**

```bash
# Run the project's test suite, e.g. cargo test, npm test, pytest, go test ./...
<project test command>
```

**If tests fail:** Stop. Fix failures before proceeding.

**If tests pass:** Continue to Step 1.5.

### Step 1.5: Security Review

Run a security review of changes on this branch:

1. Determine git range:
```bash
BASE=$(git merge-base HEAD main)
```
2. Dispatch security-reviewer subagent (from `security-review/security-reviewer.md`) with the git range
3. **If Critical findings:** Stop. Fix before proceeding.
4. **If Important findings:** Fix before proceeding, or get explicit approval from Joe to defer.
5. **If Minor only or clean:** Continue to Step 2.

### Step 2: Determine Base Branch

The base branch is whatever this work forked from — usually named in the plan, the
conversation, or the branch's upstream:

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If it is not already known, ask: "This branch split from main - is that correct?" Confirm
before opening the PR — targeting the wrong base is expensive to undo.

### Step 3: Dispatch pr-creator Agent

Dispatch the `joe-bag-of-tricks:pr-creator` agent (model: haiku) with:

- **branch**: current feature branch name
- **base**: target branch (from Step 2, usually `main`)
- **title**: conventional commit title based on the branch work

The agent pushes the branch, creates the PR with a brief summary from `git log`, and watches CI checks. It reports back with the PR URL and CI status.

**Can run in background** if you have other work to do while CI runs.

### Step 4: Handle CI Result

#### Waiting for CI — always background it

A CI run takes minutes. Blocking the session on it wastes them, so **launch the wait with
`Bash` using `run_in_background`** and pick up other work. The loop exits on its own once
every check has settled, and its completion notification brings you back:

```bash
until gh pr checks <number> --json bucket \
  --jq 'length > 0 and (map(select(.bucket == "pending")) | length == 0)' 2>/dev/null \
  | grep -qx true; do sleep 30; done
```

When the notification arrives, read the results: `gh pr checks <number>`

Three details the loop depends on:
- `length > 0` covers the window right after a push where no check has registered yet.
  Without it, an empty check list reads as "everything settled."
- The pipe into `grep` is deliberate. `gh pr checks` exits non-zero while checks are pending
  (code 8) and again when one fails; taking the exit code from `grep` instead keeps the loop alive.
- Poll at 30s. Faster only burns API quota.

#### Acting on the result

**If pr-creator reports PASSED:** Continue to Step 4.5.

**If pr-creator reports FAILED:**
1. Read the failure details from the agent's report
2. Investigate the root cause (use systematic-debugging if non-obvious)
3. Fix the issue locally
4. Commit and push the fix
5. Wait for CI in the background, per above
6. Repeat until all checks pass
7. Continue to Step 4.5

### Step 4.5: Handle CodeRabbit Reviews

After CI passes, dispatch the `joe-bag-of-tricks:coderabbit-reviewer` agent (model: sonnet) with:

- **number**: the PR number

The agent waits for CodeRabbit's review, extracts the AI agent prompt from the review body, evaluates each suggestion, auto-applies fixes, and replies to comments on GitHub.

**Can run in background** while reporting CI status to Joe.

**Handle the result based on status:**

- **`DONE`**: All suggestions handled (applied or rejected). Report what was done.
- **`NO_REVIEW`**: CodeRabbit didn't review. Continue — nothing to do.
- **`NEEDS_ESCALATION`**: Some suggestions were too complex for sonnet. Re-dispatch `coderabbit-reviewer` at **opus** with the escalated items only. Include the escalation list in the prompt so opus knows which comments to address.

After escalation, if opus also reports `NEEDS_ESCALATION`, surface the remaining items to Joe for a decision.

**After any applied changes:** Wait for CI again to verify the fixes didn't break anything —
backgrounded by default, using the loop in Step 4.

### Step 5: Cleanup Worktree

Check if the current branch has a worktree:
```bash
git worktree list | grep "$(git branch --show-current)"
```

Only clean up worktrees this plugin created — those under `.worktrees/`. If the worktree path is
outside `.worktrees/`, the host environment (harness) owns it; do **not** remove it.

If it is under `.worktrees/`:
```bash
# cd to the main repo root FIRST — `git worktree remove` fails silently when the
# current directory is inside the worktree being removed.
MAIN_ROOT=$(git worktree list --porcelain | sed -n 's/^worktree //p' | head -1)
cd "$MAIN_ROOT"
git worktree remove <worktree-path>
git worktree prune   # self-healing: clears any stale registrations
```

Report: "PR ready at <URL>. All CI checks passing."

## Merging (when Joe requests)

When Joe says to merge or close a PR, dispatch the `joe-bag-of-tricks:pr-merger` agent (model: haiku) with:

- **number**: the PR number

The agent squash merges with no body, checks out main, pulls, watches CI on the merge commit, and cleans up the local branch and worktree. It reports back with the merge SHA and CI status.

**Can run in background** if you have other work to start.

**If pr-merger reports CI FAILED on main:** Investigate and fix on a new branch.

## Quick Reference

| Step | Action |
|------|--------|
| 1. Verify | Run tests, stop if failing |
| 1.5 Security | Run security review, fix Critical/Important |
| 2. Base branch | Confirm target branch |
| 3. pr-creator | Dispatch agent: push, PR, CI watch |
| 4. CI result | Background the wait; if failed: debug, fix, push, wait again |
| 4.5 CodeRabbit | Dispatch coderabbit-reviewer: auto-apply or reject. Escalate to opus if needed |
| 5. Cleanup | Remove worktree if applicable |
| Merge | Dispatch pr-merger agent (on request) |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to push. A green run only proves the tree it ran on. |
| "The base branch is obviously main" | Confirm the fork point or ask. Targeting the wrong base is expensive to undo. |
| "The PR is open, so the work is done" | Done means CI green. Report completion only after every check passes. |
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only on Joe's explicit request. |
| "It's a one-line change, I'll just push to main" | Never push to main. Every change goes through a feature branch and a PR. |
| "A merge body documents the change nicely" | Squash merge with `--body ""`. PR detail belongs in the PR, not in git log. |
| "This other worktree looks stale — I'll clean it too" | Clean up only worktrees under `.worktrees/`. Everything else belongs to the host. |
| "CI is probably just flaky" | A red check stops the merge. Investigate the failure before touching the merge button. |
| "It's only a couple of minutes — I'll just watch CI" | Background the wait. Every time. A blocked session cannot be handed the next piece of work. |
| "There's nothing else to do, so blocking costs nothing" | You cannot know that — Joe can hand you work the moment the wait starts. Background it and stay reachable. |

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Dispatches:**
- **pr-creator** agent (haiku) - Push, PR creation, CI watch (Step 3)
- **coderabbit-reviewer** agent (sonnet, escalates to opus) - Auto-apply review suggestions (Step 4.5)
- **pr-merger** agent (haiku) - Squash merge, CI watch, cleanup (Merging)

**Pairs with:**
- **security-review** - Runs security audit before push (Step 1.5)
- **using-git-worktrees** - Cleans up worktree created by that skill

**Design rationale:** See `docs/adr/001-haiku-subagents-for-git-operations.md`.
