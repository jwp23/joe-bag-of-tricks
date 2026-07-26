# ADR-005: Retire the pr-creator Agent; One Backgrounded CI Wait

Supersedes the `pr-creator` section of `001-haiku-subagents-for-git-operations.md`. ADR-001's
`pr-merger` decision stands unchanged.

## Context

ADR-001 created two Haiku subagents for mechanical git work. `pr-creator` pushed the branch,
created the PR, and blocked on `gh pr checks --watch` until CI settled, reporting one verdict.

Separately, `finishing-a-development-branch` told the main agent to block on
`gh pr checks --watch` itself for every *subsequent* CI run — after a fix push (Step 4) and
after CodeRabbit applied changes (Step 4.5). Those waits ran on the main thread and blocked
the session for minutes at a time.

Replacing the main-thread waits with a backgrounded settle loop (`Bash` `run_in_background`
polling `gh pr checks --json bucket`) fixed the blocking, but left the workflow with **two
implementations of "wait for CI to settle"** that behaved differently:

- The loop guards the window right after a push where no check has registered yet
  (`length > 0`). `gh pr checks` exits non-zero and reports no checks in that window.
- `--watch` has no such guard, so the *first* wait — the one firing seconds after PR
  creation, most exposed to that race — was the least robust of the two.

Collapsing to the single guarded loop then removed most of what justified the agent. Against
ADR-001's own stated grounds for `pr-creator`:

| ADR-001 justification | After collapse |
|---|---|
| "Background execution frees the main agent during CI waits" | Gone — no CI wait left in the agent |
| "Slight latency from subagent spinup (negligible vs. CI wait time)" | Inverts — with no CI wait to dwarf it, spinup is the dominant cost |
| "Clean context separation" | Much smaller — the `--watch` stream and check-list parsing *were* the output volume |
| "Token cost savings on mechanical operations" | Survives, shrunken — 3-4 shell calls and a short summary |

What remains is `git push`, `git log`, `gh pr create`. That is the shape ADR-001 already
rejected under **Rejected: Committer agent** — *"Too little work per invocation — subagent
overhead exceeds inline cost."* Keeping `pr-creator` would apply that reasoning inconsistently
to two agents of equal weight.

## Decision

Delete `agents/pr-creator.md`. Fold title validation, push, and `gh pr create` into Step 3 of
`finishing-a-development-branch` as inline commands.

Every CI wait in the workflow — the initial run included — uses the one backgrounded settle
loop in Step 4. The blocking `gh pr checks --watch` appears nowhere in the skill.

Backgrounding is unconditional. An "unless you have nothing else to do" carve-out is a
rationalization loophole, not a fallback: a blocked session cannot be handed the next piece
of work, and the agent cannot know in advance that none is coming. The same wording fix
applies to the `coderabbit-reviewer` and `pr-merger` dispatches, which previously said
"can run in background *if you have other work.*"

The mechanical guarantees `pr-creator` enforced are preserved as skill text: the
conventional-commit title check is a stop rather than a guess, raw check status is reported
without "blocking / non-blocking" interpretation, and a rejected push is investigated rather
than force-pushed.

## Trade-offs

**Chosen: inline PR creation, one wait implementation**

- One implementation of the CI wait, uniformly guarded — the `length > 0` fix lands once.
- No dispatch overhead for 3-4 shell calls.
- Consistent with ADR-001's own committer-agent reasoning.
- Fewer moving parts in the finish path: one less agent to keep in sync with the skill.

**Rejected: keep pr-creator, port the guard into it**

- Preserves an agent whose primary justification (backgrounded CI waiting) no longer exists.
- Pays for it with permanent duplication in the most failure-prone part of the flow — two
  wait implementations that must be kept in agreement forever.

**Cost accepted: main context absorbs the PR-creation output**

- `git log --oneline` for the branch, push output, and the created PR URL now land in the
  main agent's context. On a squash-merge workflow, branches carry few commits, so this is a
  handful of lines. If branches ever grow long enough that summarizing the log is itself
  expensive, revisit — that, not the shell calls, would be the reason to reintroduce an agent.

**Cost accepted: title validation is now advisory text, not a separate checker**

- A dedicated mechanical agent could not be talked out of rejecting a malformed title; a
  skill instruction can be rationalized past. Mitigated by stating it as a stop condition,
  but it is a real reduction in enforcement strength.
