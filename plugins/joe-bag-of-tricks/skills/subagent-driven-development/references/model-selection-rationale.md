# Model Selection: Rationale

Prose supporting the tier-selection table and escalation ladder in SKILL.md's Model Selection
section. The table and the fire-conditions themselves are the operative rules and stay resident
— this file is why they're set that way, not a decision point a controller needs mid-run.

**Most implementation tasks are mechanical when the plan is well-specified.** Plans from writing-plans include code snippets, file paths, and acceptance criteria — enough context for `implementer-mechanical` to succeed.

**Turn count beats token price.** Wall-clock and context cost scale with how many turns a subagent takes, and the cheapest models routinely take 2-3× the turns on multi-step work — costing more overall. Use `sonnet` as the floor for reviewers, and `implementer` as the floor for implementers working from prose descriptions. When the task's plan text contains the complete code to write, the implementation is transcription plus testing: dispatch `implementer-mechanical` for that task. Single-file mechanical fixes also take the cheapest tier.

**Complexity signals for implementers:**
- Touches 1-2 files with a complete spec → `implementer-mechanical`
- Touches multiple files with integration concerns → `implementer`
- Requires design judgment or broad codebase understanding → `implementer-complex`

**Review tasks:** choose the model with the same judgment, scaled to the diff's size, complexity, and risk. A small mechanical diff does not need `opus`; a subtle concurrency change does — escalate the task reviewer to `opus` for those.

**Escalation.** You cannot reliably see what you are missing. That is a property of models,
not of tiers — an orchestrator on the top tier is as blind to its own gaps as one on a
mid-tier model, so never escalate because a call *feels* hard. Escalate when one of these
fires, each detectable by counting or comparing: (see the trigger table in SKILL.md's Model
Selection section for the fire-conditions themselves).
