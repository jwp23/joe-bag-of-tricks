# Common Rationalizations

Excuses controllers make mid-loop, and why each one is wrong. Referenced from SKILL.md's
Task Loop; content moved here verbatim during the s31 progressive-disclosure pass.

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Reviewer found spec gaps = not done. Fix or hit the cap and adjudicate — those are the only exits. |
| "I'll fix it myself, dispatching is overhead" | Controller fixes pollute your context and skip review. Resume the implementer. |
| "One more round will converge" | Past the cap, rounds don't converge — the failure is structural. Adjudicate and route. |
| "The reviewer will just find something new anyway" | Scoped re-reviews verify fixes; they cannot wander. New findings on untouched code go to the task bead, not the loop. |
| "This finding is obviously wrong, I'll drop it" | You adjudicate only at the cap, and every ruling is a `bd note`. Silent discards are forbidden. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Reviews slow the loop down" | The loop without reviews is just unverified churn. Reviews are the loop's brakes and steering. Overlap the wait, never the gate. |
| "This review will be clean too, I'll overlap it" | Overlap has two conditions, both checkable: N+1 mechanical, and N mechanical with a plain DONE. Complex, DONE_WITH_CONCERNS, or mid-fix-round means wait — expecting clean is not one of the conditions. |
| "N's review found something; I'll rebase the fix under N+1" | Never rewrite history under a live implementer. Fix commits go on top, and the scoped re-review's FIX_BASE is the HEAD just before the fix dispatch. |
| "Overlapping is bookkeeping I can keep in my head" | It is a moving base. `bd note` it on N+1 before dispatch or don't overlap — after compaction the note is the only thing that says N+1 built on unreviewed work. |
| "These four tasks are each their own task, so each gets its own dispatch" | Same shape, same package, no independent review surface = one dispatch. Four cold starts and four test gates buy one reviewable unit. |
| "The epic's children are the tasks" | They are whatever the tree says. `bd children <epic-id> --pretty` shows every level and totals it; `--json` returns one level. A feature layer mistaken for the task layer ships its tasks undelivered — and you rule against requirements you never read. |
| "All the beads I saw are closed, close the parent" | You saw one level. `bd children <id>` before every parent close — `bd close` and `bd epic status` both ignore grandchildren. |
| "I'll track progress in my head, bd is bookkeeping" | bd is what survives compaction. Controllers without it have re-dispatched entire completed task sequences. |
| "The subagent can close its own bead" | Subagents never touch bd, remotes, or PRs. You own all durable state. |
| "That discovered issue is out of scope, skip it" | File it: `bd create ... --deps discovered-from:<task-id>`. Unfiled discoveries are lost. |
| "A fork is the safest resume — it has all the context" | That's why it's the most expensive dispatch possible. A fix round needs the brief, the report, and the findings — not your whole session. Resume or go cheap. |
| "Inline reviewer reports are easier to adjudicate" | You adjudicate from the findings list. The full report belongs in a file — inline prose taxes every turn for the rest of the session. |
| "This decision feels hard, I should handle it carefully myself" | Feeling hard IS the trigger signal you can't trust. Check the structural triggers; if one fires, dispatch an adjudicator. |
| "The implementer spawned its own reviewer — free extra assurance" | It's a duplicate seat reviewing the same diff; the task review is the gate. A worker-spawned reviewer is a defect to flag, not rigor. |
| "This needs a human — I'll park the run and wait" | Only the four stop classes stop you. Everything else is a ruling: decide, bd note it, keep going. The roll-up at Finish is where it reaches them. |
| "I'll summarize the report in my own words for the bd note" | The report already has paste-ready bd note text. Re-narrating it is the 121KB-of-typed-notes failure mode. Paste it. |
| "I forgot the ID, let me `bd list \| grep` for it" | `bd create` printed it. A bead you created this session is a scroll-back, not a search. |
