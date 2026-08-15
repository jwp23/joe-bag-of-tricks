# Plan Steps Name a Procedure's File, Never a Skill to Invoke

## Decision

A task design dispatched to an implementer subagent never says "invoke skill X" or "run
`/command`". It says "follow the procedure in `<path>`", and where that path will not be
readable from the worktree, the plan writes out the steps the task actually needs.

Enforced at three points, one line of defence each:

- **`writing-plans`** — "invoke the X skill" / "run `/command`" joins the No Placeholders list
  as a plan failure, so the trap is caught where it is authored.
- **`subagent-driven-development`** — the Pre-Flight Plan Review scan gains a row for it, so a
  plan that already carries the defect is ruled on before execution rather than at dispatch
  time. The ruling is a rewrite to "follow the procedure in `<path>`", or, when the file is not
  readable from the worktree, the controller putting what the step needs into that dispatch's
  task-specific instructions itself.
- **`implementer-contract`** — the contract already banned invoking skills, but stated no
  recovery. It now says: read the file the procedure lives in and follow it directly; if you
  cannot locate that file, report NEEDS_CONTEXT rather than reconstructing it from memory.

Rejected as the general fix: adding the named skill to the implementer agents' `skills:`
frontmatter.

## Rationale

- The three implementer agents grant `Bash, Read, Edit, Write, Grep, Glob` and no Skill tool.
  "Invoke skill X" in a task design is structurally impossible to follow, and the failure is
  quiet — the implementer on joe-bag-of-tricks-zfi.6 recovered by reading `readme-sync/SKILL.md`
  by hand, which worked only because that skill happened to be a file in the repo being edited.
  Nothing in the pipeline noticed.
- `skills:` frontmatter (the mechanism proved in
  [implementer-contract-as-preloaded-skill](implementer-contract-as-preloaded-skill.md)) only
  reaches skills known when the agent definition is written. The set a plan might name is
  open-ended — `readme-sync`, `record-decision`, `verification-before-completion`,
  `test-driven-development` — and every entry is preloaded into *every* dispatch of that tier,
  paid whether the task needs it or not. Preloading is the right tool for text that applies to
  all dispatches, which is why the contract itself uses it, and the wrong tool for a per-task
  procedure. It stays available for a future skill that genuinely does apply to every
  implementer dispatch; that would be its own decision.
- Naming the file is what an implementer with Read can always act on, and it degrades
  legibly rather than silently: an unreadable path is a NEEDS_CONTEXT the controller sees,
  not a hand-reconstructed procedure that looks like success in the report.
- The controller keeps the escape hatch because it is the one node in the pipeline that *does*
  hold the Skill tool. When a step needs a procedure the implementer cannot read, the fix is the
  controller inlining it into the dispatch — not the implementer improvising.
- The three edits are additive: five lines to `writing-plans`, five to
  `subagent-driven-development`, three to `implementer-contract`. No skill was restructured, and
  no skill description changed, so the context budget is untouched.
- Placing the SDD half in Pre-Flight rather than at dispatch follows
  [sdd-rulings-not-stalls](sdd-rulings-not-stalls.md): this is a plan defect, the controller
  rules on it, and Pre-Flight is where plan defects are already found and ruled on in one pass.
- Decided 2026-08-14 while closing joe-bag-of-tricks-xhc.
