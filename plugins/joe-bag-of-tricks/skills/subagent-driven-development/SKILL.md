---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration

**Narration:** between tool calls, narrate at most one short line — bd state and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

## When to Use

```dot
digraph when_to_use {
    "Have implementation plan?" [shape=diamond];
    "Tasks mostly independent?" [shape=diamond];
    "Stay in this session?" [shape=diamond];
    "subagent-driven-development" [shape=box];
    "executing-plans" [shape=box];
    "Manual execution or brainstorm first" [shape=box];

    "Have implementation plan?" -> "Tasks mostly independent?" [label="yes"];
    "Have implementation plan?" -> "Manual execution or brainstorm first" [label="no"];
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
}
```

**vs. Executing Plans (parallel session):**
- Same session (no context switch)
- Fresh subagent per task (no context pollution)
- Review after each task (spec compliance + code quality), broad review at the end
- Faster iteration (no human-in-loop between tasks)

## The Process

```dot
digraph process {
    rankdir=TB;

    subgraph cluster_per_task {
        label="Per Task";
        "Claim task:\nbd update <task-id> --claim" [shape=box];
        "Run task-brief <task-id>" [shape=box];
        "Dispatch implementer subagent\n(model: haiku|sonnet|opus)\n(./implementer-prompt.md)" [shape=box];
        "Implementer subagent asks questions?" [shape=diamond];
        "Answer questions, provide context" [shape=box];
        "Implementer subagent implements, tests,\ncommits, self-reviews, writes report file" [shape=box];
        "Create beads for discovered work\n(if implementer reported any)" [shape=box];
        "Run review-package BASE HEAD" [shape=box];
        "Dispatch task reviewer subagent\n(model: per judgment, default sonnet)\n(./task-reviewer-prompt.md)" [shape=box];
        "Task reviewer reports spec OK/warn and quality approved?" [shape=diamond];
        "Dispatch fix subagent for Critical/Important findings" [shape=box];
        "Close task bead:\nbd close <task-id> --reason \"commits <base7>..<head7>, review clean\"" [shape=box];
    }

    "Load epic features:\nbd children <epic-id> --json" [shape=box];
    "Load feature tasks:\nbd children <feature-id> --json" [shape=box];
    "More tasks in feature?" [shape=diamond];
    "Close feature:\nbd close <feature-id>" [shape=box];
    "More features remain?" [shape=diamond];
    "Close epic:\nbd close <epic-id>" [shape=box];
    "Run review-package MERGE_BASE HEAD,\ndispatch final code reviewer\n(../requesting-code-review/code-reviewer.md)" [shape=box];
    "Use finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];

    "Load epic features:\nbd children <epic-id> --json" -> "Load feature tasks:\nbd children <feature-id> --json";
    "Load feature tasks:\nbd children <feature-id> --json" -> "Claim task:\nbd update <task-id> --claim";
    "Claim task:\nbd update <task-id> --claim" -> "Run task-brief <task-id>";
    "Run task-brief <task-id>" -> "Dispatch implementer subagent\n(model: haiku|sonnet|opus)\n(./implementer-prompt.md)";
    "Dispatch implementer subagent\n(model: haiku|sonnet|opus)\n(./implementer-prompt.md)" -> "Implementer subagent asks questions?";
    "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
    "Answer questions, provide context" -> "Dispatch implementer subagent\n(model: haiku|sonnet|opus)\n(./implementer-prompt.md)";
    "Implementer subagent asks questions?" -> "Implementer subagent implements, tests,\ncommits, self-reviews, writes report file" [label="no"];
    "Implementer subagent implements, tests,\ncommits, self-reviews, writes report file" -> "Create beads for discovered work\n(if implementer reported any)";
    "Create beads for discovered work\n(if implementer reported any)" -> "Run review-package BASE HEAD";
    "Run review-package BASE HEAD" -> "Dispatch task reviewer subagent\n(model: per judgment, default sonnet)\n(./task-reviewer-prompt.md)";
    "Dispatch task reviewer subagent\n(model: per judgment, default sonnet)\n(./task-reviewer-prompt.md)" -> "Task reviewer reports spec OK/warn and quality approved?";
    "Task reviewer reports spec OK/warn and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
    "Dispatch fix subagent for Critical/Important findings" -> "Run review-package BASE HEAD" [label="re-review"];
    "Task reviewer reports spec OK/warn and quality approved?" -> "Close task bead:\nbd close <task-id> --reason \"commits <base7>..<head7>, review clean\"" [label="yes"];
    "Close task bead:\nbd close <task-id> --reason \"commits <base7>..<head7>, review clean\"" -> "More tasks in feature?";
    "More tasks in feature?" -> "Claim task:\nbd update <task-id> --claim" [label="yes"];
    "More tasks in feature?" -> "Close feature:\nbd close <feature-id>" [label="no"];
    "Close feature:\nbd close <feature-id>" -> "More features remain?";
    "More features remain?" -> "Load feature tasks:\nbd children <feature-id> --json" [label="yes"];
    "More features remain?" -> "Close epic:\nbd close <epic-id>" [label="no"];
    "Close epic:\nbd close <epic-id>" -> "Run review-package MERGE_BASE HEAD,\ndispatch final code reviewer\n(../requesting-code-review/code-reviewer.md)";
    "Run review-package MERGE_BASE HEAD,\ndispatch final code reviewer\n(../requesting-code-review/code-reviewer.md)" -> "Use finishing-a-development-branch";
}
```

## Pre-Flight Plan Review

Before claiming Task 1, scan the bd hierarchy once for conflicts. The bd
hierarchy IS the plan — there is no markdown plan file to read instead: walk
`bd children <epic-id> --json`, then `bd children <feature-id> --json` for
each feature, the same two-level traversal the process above uses.

- tasks that contradict each other or the epic's Global Constraints
  (`bd show <epic-id>` — the design field set during writing-plans)
- anything a task's design explicitly mandates that the review rubric treats
  as a defect (a test that asserts nothing, verbatim duplication of a logic
  block)

Present everything you find to your human partner as one batched question —
each finding beside the task text that mandates it, asking which governs —
before execution begins, not one interrupt per discovery mid-plan. If the
scan is clean, proceed without comment. The review loop remains the net for
conflicts that only emerge from implementation.

## Model Selection

Use the least powerful model that can handle each role. Start cheap, escalate on failure.

The Agent tool accepts `model: "haiku" | "sonnet" | "opus"`. Use this table:

| Role | Model | Why |
|------|-------|-----|
| Implementer (mechanical) | `haiku` | Clear spec, 1-2 files, plan provides code snippets. Review stage catches mistakes. |
| Implementer (integration) | `sonnet` | Multi-file coordination, message passing, pattern matching. |
| Implementer (complex) | `opus` | Design judgment, broad codebase understanding, architectural decisions. |
| Task reviewer (spec + quality) | `sonnet` | One dispatch covers both a structured spec comparison and a judgment-heavy quality read. Escalate to `opus` for a subtle or high-risk diff (see Review tasks below) — never drop to `haiku`: it caught 0/10 planted defects in upstream's own evaluation and rationalized them away. |
| Final reviewer | `opus` | Holistic assessment across the entire branch. |

**Most implementation tasks are mechanical when the plan is well-specified.** Plans from writing-plans include code snippets, file paths, and acceptance criteria — enough context for haiku to succeed.

**Turn count beats token price.** Wall-clock and context cost scale with how many turns a subagent takes, and the cheapest models routinely take 2-3× the turns on multi-step work — costing more overall. Use `sonnet` as the floor for reviewers and for implementers working from prose descriptions. When the task's plan text contains the complete code to write, the implementation is transcription plus testing: use `haiku` for that implementer. Single-file mechanical fixes also take the cheapest tier.

**Complexity signals for implementers:**
- Touches 1-2 files with a complete spec → `haiku`
- Touches multiple files with integration concerns → `sonnet`
- Requires design judgment or broad codebase understanding → `opus`

**Review tasks:** choose the model with the same judgment, scaled to the diff's size, complexity, and risk. A small mechanical diff does not need `opus`; a subtle concurrency change does — escalate the task reviewer to `opus` for those.

**Escalation is the safety net:** If haiku reports BLOCKED, re-dispatch with sonnet. If sonnet reports BLOCKED, re-dispatch with opus. Never retry the same model without changing something (see Handling Implementer Status).

**Always specify the model explicitly when dispatching a subagent.** An omitted model inherits your session's model — often the most capable and most expensive — which silently defeats this section.

## Handling Implementer Status

Implementer subagents report one of four statuses. Handle each appropriately:

**DONE:** Generate the review package (`scripts/review-package BASE HEAD`, from this skill's directory — it prints the unique file path it wrote; BASE is the commit you recorded before dispatching the implementer — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task), then dispatch the task reviewer with the printed path.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Handling Reviewer ⚠️ Items

The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
that live in unchanged code or span tasks. These do not block the rest of the
review, but you must resolve each one yourself before marking the task
complete: you hold the plan and cross-task context the reviewer
lacks. If you confirm an item is a real gap, treat it as a failed spec
review — send it back to the implementer and re-review.

## Constructing Reviewer Prompts

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. When you fill a reviewer template:

- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.
- The global-constraints block you hand the reviewer is its attention
  lens. Copy the binding requirements verbatim from the epic's Global
  Constraints (`bd show <epic-id>` — the design field set during
  writing-plans) or the spec: exact values, exact formats, and the stated
  relationships between components ("same layout as X", "matches Y"). The
  reviewer's template already carries the process rules (YAGNI, test
  hygiene, review method) — the constraints block is for what THIS
  project's spec demands.
- Hand the reviewer its diff as a file: run this skill's
  `scripts/review-package BASE HEAD` and pass the reviewer the file path
  it prints (or, without bash: `git log --oneline`, `git diff --stat`,
  and `git diff -U10` for the range, redirected to one uniquely named
  file). The output never enters your own context, and the reviewer sees
  the commit list, stat summary, and full diff with context in one Read
  call. Use the BASE you recorded before dispatching the implementer —
  never `HEAD~1`, which silently truncates multi-commit tasks.
- A dispatch prompt describes one task, not the session's history. Do not
  paste accumulated prior-task summaries ("state after Tasks 1-3") into
  later dispatches — a real session's dispatch hit 42k chars of which 99%
  was pasted history. A fresh subagent needs its task, the interfaces it
  touches, and the global constraints. Nothing else.
- Dispatch fix subagents for Critical and Important findings. Record Minor
  findings with `bd note <task-id> "Minor: ..."` as you go, and point the
  final whole-branch review at the closed tasks so it can triage which must
  be fixed before merge (`bd show <task-id>` per task under the epic). A
  roll-up nobody reads is a silent discard.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is the human's decision, like any plan
  contradiction: present the finding and the plan text, ask which governs.
  Do not dismiss the finding because the plan mandates it, and do not
  dispatch a fix that contradicts the plan without asking.
- The final whole-branch review gets a package too: run
  `scripts/review-package MERGE_BASE HEAD` (MERGE_BASE = the commit the
  branch started from, e.g. `git merge-base main HEAD`) and include the
  printed path in the final review dispatch, so the final reviewer reads
  one file instead of re-deriving the branch diff with git commands.
- Every fix dispatch carries the implementer contract: the fix subagent
  re-runs the tests covering its change and reports the results. Name the
  covering test files in the dispatch — a one-line fix does not need the
  whole suite. Before re-dispatching the reviewer, confirm the fix report
  contains the covering tests, the command run, and the output; dispatch
  the re-review once all three are present.
- If the final whole-branch review returns findings, dispatch ONE fix
  subagent with the complete findings list — not one fixer per finding.
  Per-finding fixers each rebuild context and re-run suites; a real
  session's final-review fix wave cost more than all its tasks combined.

## File Handoffs

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files:

- **Task brief:** before dispatching an implementer, run this skill's
  `scripts/task-brief <task-id>` — it reads the task straight out of bd
  (`bd show <task-id> --json`: title, description, design, notes) into a
  uniquely named file and prints the path. Compose the dispatch so the
  brief stays the single source of requirements. Your dispatch should
  contain: (1) one line on where this task fits in the project; (2) the
  brief path, introduced as "read this first — it is your requirements,
  with the exact values to use verbatim"; (3) interfaces and decisions
  from earlier tasks that the brief cannot know; (4) your resolution of
  any ambiguity you noticed in the brief; (5) the report-file path and
  report contract. Exact values (numbers, magic strings, signatures, test
  cases) appear only in the brief.
- **Report file:** name the implementer's report file after the brief
  (brief `…/task-<task-id>-brief.md` → report `…/task-<task-id>-report.md`)
  and put it in the dispatch prompt. The implementer writes the full report
  there and returns only status, commits, a one-line test summary, and
  concerns.
- **Reviewer inputs:** the task reviewer gets three paths — the same brief
  file, the report file, and the review package — plus the global
  constraints that bind the task.
- Fix dispatches append their fix report (with test results) to the same
  report file and return a short summary; re-reviews read the updated file.

## Durable Progress

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed task
sequences — the single most expensive failure observed. Progress rides on
bd, not a separate ledger file — a second ledger would duplicate state a
beads-only-tracking project already tracks for free.

- At skill start (or after any compaction), reload the hierarchy:
  `bd children <epic-id> --json` and, per feature, `bd children
  <feature-id> --json` (`bd children` includes closed issues by default).
  Tasks bd already shows `closed` are DONE — do not re-dispatch them;
  resume at the first task not `closed`.
- When a task's review comes back clean, close it in the same message as
  your other bookkeeping, with the commit range as the reason:
  `bd close <task-id> --reason "commits <base7>..<head7>, review clean"`.
  The reason is your recovery breadcrumb — the commits it names exist in
  git even when your context no longer remembers creating them.
- If a task needs a note before it's ready to close (a mid-review finding,
  a concern to carry forward), use `bd note <task-id> "..."` — it appends
  to the task's notes field without changing status.
- After compaction, trust `bd show` / `bd children` and `git log` over your
  own recollection.
- The `.joe-bag-of-tricks/sdd/` workspace (briefs, reports, review
  packages) is disposable scratch, not the record — losing it (`git clean
  -fdx` included) costs nothing; bd and git are the only durable state.

## Prompt Templates

- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
- Final whole-branch review: use requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)

## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Load epic features: bd children <epic-id> --json]

--- Feature 1 (bd-feat1): Hook system ---

[Load feature tasks: bd children bd-feat1 --json]

Task 1 (bd-abc): Hook installation script
  Complexity: 1-2 files, clear spec with code snippets → model: haiku

[bd update bd-abc --claim]
[Run scripts/task-brief bd-abc; prints .../task-bd-abc-brief.md]
[Dispatch implementer subagent (model: haiku) with brief path + report path + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.local/share/my-app/hooks/)"

[Re-dispatch implementer (model: haiku) with answer + full context]
Implementer:
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed
  - Wrote full report to .../task-bd-abc-report.md; returned a <15-line status summary

[Run scripts/review-package BASE HEAD; dispatch task reviewer (model: sonnet)
 with the brief, report, and diff-package paths]
Task reviewer: Spec ✅ - all requirements met, nothing extra.
  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.

[Both verdicts passed — close the task bead with the commit-range breadcrumb]
[bd close bd-abc --reason "commits abc123f..def456a, review clean"]

Task 2 (bd-def): Recovery modes
  Complexity: multi-file, integration with hook system → model: sonnet

[bd update bd-def --claim; task-brief; dispatch implementer (model: sonnet) with full context]
Implementer: reports DONE, discovered work: "Found edge case in error path"
[Create bead for discovered work: bd create "Edge case..." --deps discovered-from:bd-def]
[Run review-package; dispatch task reviewer (model: sonnet)]
Task reviewer: Spec ❌:
  - Missing: Progress reporting (spec says "report every 100 items")
  - Extra: Added --json flag (not requested)
  Issues (Important): Magic number (100)

[Dispatch fix subagent with all findings]
Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant

[Re-run review-package; task reviewer reviews again]
Task reviewer: Spec ✅. Task quality: Approved.

[bd close bd-def --reason "commits ghi789b..jkl012c, review clean"]

[All tasks in feature done — close feature]
[bd close bd-feat1 --reason "All tasks complete"]

--- Feature 2 (bd-feat2): Verification ---

[Load feature tasks: bd children bd-feat2 --json]

Task 3 (bd-ghi): Verify command
  Complexity: design judgment, broad codebase understanding → model: opus

[bd update bd-ghi --claim; task-brief; dispatch implementer (model: opus)]
...implement, task reviewer (model: sonnet, escalated to opus — diff touches
shared verification core), close...
[bd close bd-ghi --reason "commits mno345d..pqr678e, review clean"]

[All tasks in feature done — close feature]
[bd close bd-feat2 --reason "All tasks complete"]

--- All features complete ---

[All features closed — close epic]
[bd close <epic-id> --reason "All features complete"]

[Run scripts/review-package MERGE_BASE HEAD; dispatch final code reviewer
 (model: opus) with the printed path — requesting-code-review's code-reviewer.md]
Final reviewer: All requirements met, ready to merge

Done!
```

## Advantages

**vs. Manual execution:**
- Subagents follow TDD naturally
- Fresh context per task (no confusion)
- Parallel-safe (subagents don't interfere)
- Subagent can ask questions (before AND during work)

**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic

**Efficiency gains:**
- Controller curates exactly what context is needed; bulk artifacts move
  as files, not pasted text
- Subagent gets complete information upfront
- Questions surfaced before work begins (not after)
- Durable progress rides on bd state — no separate ledger file to maintain

**Quality gates:**
- Self-review catches issues before handoff
- Task review carries two verdicts: spec compliance and code quality
- Review loops ensure fixes actually work
- Spec compliance prevents over/under-building
- Code quality ensures implementation is well-built

**Cost:**
- More subagent invocations (implementer + reviewer per task)
- Controller does more prep work (extracting all tasks upfront)
- Review loops add iterations
- But catches issues early (cheaper than debugging later)

## Red Flags

**Never:**
- Start implementation on main/master branch without explicit user consent
- Skip task review, or accept a report missing either verdict (spec compliance AND task quality are both required)
- Proceed with unfixed issues
- Dispatch multiple implementation subagents in parallel (conflicts)
- Make a subagent read bd issues directly (hand it its task brief —
  `scripts/task-brief` — instead)
- Let subagents create or close bd issues, push to remote, or create PRs (controller manages all of these)
- Skip scene-setting context (subagent needs to understand where task fits)
- Ignore subagent questions (answer before letting them proceed)
- Accept "close enough" on spec compliance (reviewer found spec issues = not done)
- Skip review loops (reviewer found issues = implementer fixes = review again)
- Let implementer self-review replace actual review (both are needed)
- Tell a reviewer what not to flag, or pre-rate a finding's severity in the
  dispatch prompt ("treat it as Minor at most") — the plan's example code is
  a starting point, not evidence that its weaknesses were chosen
- Dispatch a task reviewer without a diff file — generate it first
  (`scripts/review-package BASE HEAD`) and name the printed path in the
  prompt
- Move to next task while the review has open Critical/Important issues
- Close a task bead before the task reviewer's report shows spec ✅ (or
  every ⚠️ resolved) and task quality Approved
- Close a feature without verifying all its task beads are closed
- Close the epic without verifying all features are closed
- Ignore discovered work reported by implementers (create beads with `discovered-from` links)
- Re-dispatch a task bd already shows `closed` — check `bd show
  <task-id>` (and `git log`) after any compaction or resume

**If subagent asks questions:**
- Answer clearly and completely
- Provide additional context if needed
- Don't rush them into implementation

**If reviewer finds issues:**
- Implementer (same subagent) fixes them
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

**If subagent fails task:**
- Dispatch fix subagent with specific instructions
- Don't try to fix manually (context pollution)

## Integration

**Required workflow skills:**
- **using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **writing-plans** - Creates the bd task hierarchy this skill executes
- **requesting-code-review** - Code review template for the final whole-branch review
- **finishing-a-development-branch** - Complete development after all tasks

**Subagents should use:**
- **test-driven-development** - Subagents follow TDD for each task

**Alternative workflow:**
- **executing-plans** - Use for parallel session instead of same-session execution
