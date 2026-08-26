---
name: finishing-a-development-branch
description: Use when implementation is complete and all tests pass - handles the push, PR creation, and CI verification workflow
---

# Finishing a Development Branch

## Overview

Complete development work by pushing the feature branch, creating a PR, and waiting for CI to pass.

**Core principle:** Verify tests -> Push -> PR -> Wait for CI -> Handle CodeRabbit reviews -> Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## Orchestrating Multiple Branches

Steps 1-2 below (verify tests, security review, confirm base branch) happen per branch, in
this session, before a branch is ready to hand off — they need the working tree and your
judgment.

Once one or more branches are review-clean and ready to ship, decide how many you're
delivering:

- **One branch, staying in the loop:** Run Step 3 onward yourself, as written below.
- **Two or more branches, or you want the whole delivery tail run unattended:** Dispatch the
  `joe-bag-of-tricks:branch-shepherd` agent once with the full branch list (each entry: worktree
  path, optional existing PR number). It runs Step 3 through Merging for every branch —
  push/PR, the backgrounded CI wait and fix loop, CodeRabbit handling, conflict reconciliation
  if main moves mid-train, squash-merge, and worktree cleanup — sequentially, and reports one
  outcome table at the end instead of checking in after each step.

This does not replace Steps 3-5 as the *reference procedure* — branch-shepherd runs the same
steps, just autonomously and across a list. Read them below regardless of which path you take;
they're what branch-shepherd is executing on your behalf.

**Dispatch it in the background** and keep working while it runs.

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
4. **If Important findings:** Fix before proceeding, or get explicit approval from your human partner to defer.
5. **If Minor only or clean:** Continue to Step 2.

### Step 2: Determine Base Branch

The base branch is whatever this work forked from — usually named in the plan, the
conversation, or the branch's upstream:

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If it is not already known, ask: "This branch split from main - is that correct?" Confirm
before opening the PR — targeting the wrong base is expensive to undo.

### Step 3: Open the PR

The title MUST be a conventional commit line — `type: description`, optional scope
(`type(scope): description`). Valid types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`,
`perf`, `ci`, `style`, `build`. A title that does not match is a stop, not a guess.

```bash
git push -u origin <branch>
git log <base>..HEAD --oneline
```

Write the body from that log — one bullet per logical change, not per commit:

```
## Summary
- <bullets>

## Test Plan
- CI checks must pass
```

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

Keep the PR number from the output. If the push is rejected, the remote moved — investigate
rather than force-pushing.

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

Ending a turn "waiting" without that live background task is a stall — nothing will ever wake
you, and the delivery strands until someone notices. A promise to wait is not a wait: if
launching the loop did not return a task ID you can name, no wait exists — launch it before
ending the turn. Do not substitute sleeps, scheduled wakeups, or one-off checks for the loop.

Three details the loop depends on:
- `length > 0` covers the window right after a push where no check has registered yet.
  Without it, an empty check list reads as "everything settled."
- The pipe into `grep` is deliberate. `gh pr checks` exits non-zero while checks are pending
  (code 8) and again when one fails; taking the exit code from `grep` instead keeps the loop alive.
- Poll at 30s. Faster only burns API quota.

#### Acting on the result

Read the settled results with `gh pr checks <number>`. Report the raw status — do not
classify a check as "blocking" or "non-blocking," and do not decide a failure does not matter.

**If every check passed:** Continue to Step 4.5.

**If any check failed:**
1. Note every failing check name and its URL
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

**Dispatch it in the background** and keep working while it runs.

**Handle the result based on status:**

- **`DONE`**: All suggestions handled (applied or rejected). Report what was done.
- **`NO_REVIEW`**: CodeRabbit didn't review. Continue — nothing to do.
- **`NEEDS_ESCALATION`**: Some suggestions were too complex for sonnet. Re-dispatch `coderabbit-reviewer` at **opus** with the escalated items only. Include the escalation list in the prompt so opus knows which comments to address.

After escalation, if opus also reports `NEEDS_ESCALATION`, surface the remaining items to your human partner for a decision.

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

**If removal is refused** (`contains modified or untracked files`): the
worktree holds files that exist nowhere else — uncommitted plans, notes,
or scratch work. Never `--force` on your own initiative. Show your human
partner what is at stake and ask:

```bash
git -C "$WORKTREE_PATH" status --porcelain -uall
```

```
Worktree removal refused — these files were never committed:

<file list>

1. Commit them to <branch> before cleanup
2. Move them into <main repo root>
3. Delete them (unrecoverable)

Which?
```

Carry out the choice, then remove the worktree.

Report: "PR ready at <URL>. All CI checks passing."

## Merging (when your human partner requests)

When your human partner says to merge or close a PR, dispatch the `joe-bag-of-tricks:pr-merger` agent (model: haiku) with:

- **number**: the PR number

The agent squash merges with no body, checks out main, pulls, verifies CI — requiring *every*
Actions run on the merge commit to have succeeded when the repo triggers any, falling back to
the PR gate when it triggers none — and cleans up the local branch and worktree. Its post-merge
wait is the same backgrounded settle loop as Step 4, polling `gh run list --commit` rather than
`gh pr checks`; `--watch` appears nowhere. It reports back with the merge SHA and CI status.

**Dispatch it in the background** and keep working while it runs.

**If pr-merger reports CI FAILED on main:** Investigate and fix on a new branch.

**If it reports INCOMPLETE, or PASSED from the PR gate with no Actions run detected:** that is
not post-merge verification. Treat main as unverified and check it yourself before building on
it.

## Quick Reference

| Step | Action |
|------|--------|
| 1. Verify | Run tests, stop if failing |
| 1.5 Security | Run security review, fix Critical/Important |
| 2. Base branch | Confirm target branch |
| 2+ branches ready | Dispatch branch-shepherd with the branch list instead of Step 3-Merging manually |
| 3. Open PR | Push, `gh pr create` with a conventional-commit title |
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
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only on your human partner's explicit request. |
| "It's a one-line change, I'll just push to main" | Never push to main. Every change goes through a feature branch and a PR. |
| "A merge body documents the change nicely" | Squash merge with `--body ""`. PR detail belongs in the PR, not in git log. |
| "This other worktree looks stale — I'll clean it too" | Clean up only worktrees under `.worktrees/`. Everything else belongs to the host. |
| "Removal refused — `--force` is just finishing the cleanup" | The refusal means files exist only in that worktree. `--force` destroys them permanently. Show your human partner and ask. |
| "CI is probably just flaky" | A red check stops the merge. Investigate the failure before touching the merge button. |
| "It's only a couple of minutes — I'll just watch CI" | Background the wait. Every time. A blocked session cannot be handed the next piece of work. |
| "There's nothing else to do, so blocking costs nothing" | You cannot know that — your human partner can hand you work the moment the wait starts. Background it and stay reachable. |
| "I said I'm waiting for CI, so the wait is in place" | Only a live `run_in_background` task wakes you. No task ID = no wait. Launch the loop before ending the turn. |

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Dispatches:**
- **coderabbit-reviewer** agent (sonnet, escalates to opus) - Auto-apply review suggestions (Step 4.5)
- **pr-merger** agent (haiku) - Squash merge, CI watch, cleanup (Merging)
- **branch-shepherd** agent (sonnet) - Runs Step 3 through Merging unattended across a list of
  review-clean branches (Orchestrating Multiple Branches)

**Pairs with:**
- **security-review** - Runs security audit before push (Step 1.5)
- **using-git-worktrees** - Cleans up worktree created by that skill

**Design rationale:** Merging and review are dispatched because they are mechanical enough for a
cheap model and long enough that backgrounding them buys real time. PR creation is inline because
it is not: once every CI wait moved to the one backgrounded settle loop, `git push` + `gh pr
create` was too little work per invocation to pay for a dispatch.
