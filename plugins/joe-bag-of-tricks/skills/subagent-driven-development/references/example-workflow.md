# Example Workflow

Illustrative walkthrough of two tasks under an epic, dispatch-by-dispatch. Referenced
from SKILL.md's Task Loop; content moved here verbatim during the s31
progressive-disclosure pass.

```
You: I'm using Subagent-Driven Development to execute this plan.

[Setup: worktree verified]
[bd children <epic-id> --pretty — 2 features, 5 tasks, Total: 8 issues across
 3 levels; none closed, fresh start]
[Pre-flight scan noted on the epic: "Scan: 8 issues across 3 levels — ..."]

--- Feature 1 (bd-feat1): Hook system ---

[Load feature tasks: bd children bd-feat1 --json]

Task 1 (bd-abc): Hook installation script
  Complexity: 1-2 files, clear spec with code snippets → implementer-mechanical

[bd update bd-abc --claim; record BASE]
[Run scripts/task-brief bd-abc; prints .../task-bd-abc-brief.md]
[Dispatch joe-bag-of-tricks:implementer-mechanical with brief path + report path + context]

Implementer: "Before I begin - should the hook be installed at user or system level?"

You: "User level (~/.local/share/my-app/hooks/)"

Implementer: [Later]
  - Implemented install-hook command
  - Added tests, 5/5 passing
  - Self-review: Found I missed --force flag, added it
  - Committed
  - Wrote full report to .../task-bd-abc-report.md; returned a <15-line status summary

[Run scripts/review-package BASE HEAD; dispatch task reviewer (model: sonnet)
 with the brief, report, diff-package, and review-file paths]
Task reviewer: Spec ✅. Task quality: Approved. No Critical/Important findings.
  Full report: .../task-bd-abc-review.md

[bd close bd-abc --reason "commits abc123f..def456a, review clean"]

Task 2 (bd-def): Recovery modes
  Complexity: multi-file, integration with hook system → implementer

[bd update bd-def --claim; task-brief; dispatch joe-bag-of-tricks:implementer]
Implementer: reports DONE, discovered work: "Found edge case in error path"
[bd create --title="Edge case in error path" ... --deps discovered-from:bd-def]
[Run review-package BASE HEAD; dispatch task reviewer (model: sonnet)
 with the brief, report, diff-package, and review-file paths]
Task reviewer: Spec ❌:
  - Missing: Progress reporting (spec says "report every 100 items")
  Issues (Important): Magic number (100)
  Full report: .../task-bd-def-review.md

[Fix round 1: resume the implementer with both findings]
Implementer: Added progress reporting, extracted PROGRESS_INTERVAL constant.
  Re-ran test/recovery.test.js — 10/10 passing. Fix report appended.

[Run review-package FIX_BASE HEAD; dispatch scoped re-review (model: haiku)
 appending to .../task-bd-def-review.md]
Re-reviewer: Missing progress reporting — ADDRESSED (src/recovery.js:41).
  Magic number — ADDRESSED (src/recovery.js:7). New breakage: none.
  Verdict: all findings addressed. Full report: .../task-bd-def-review.md

[bd note bd-def "Fix round 1/5: 2 addressed, 0 open; commits d4e5f6a..b7c8d9e"]
[bd close bd-def --reason "commits ghi789b..jkl012c, review clean"]

[bd children bd-feat1 — every row ✓; bd close bd-feat1 --reason "All tasks complete"]

--- Feature 2 (bd-feat2): Verification ---
...
[bd children <epic-id> — all 8 rows ✓; bd close <epic-id> --reason "All features complete"]

[Run scripts/review-package MERGE_BASE HEAD; dispatch final code reviewer
 (model: fable; top-available-tier fallback if not in roster) with the printed path —
 requesting-code-review's code-reviewer.md]
Final reviewer: All requirements met. Deferred minors triaged: none block merge.

[Delete the SDD workspace — the record now lives in bd and git]

Done! Using finishing-a-development-branch.
```
