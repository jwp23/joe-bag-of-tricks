# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

The implementer's operating contract — scope boundaries, escalation, self-review, and report
format — is **already in the subagent's context**: each implementer agent preloads the
`implementer-contract` skill through its `skills:` frontmatter. Do not restate it here. This
prompt carries only what is specific to this dispatch: which task, where the brief and report
files are, and any context the agent cannot derive from the brief.

```
Subagent ([AGENT TYPE — REQUIRED: joe-bag-of-tricks:implementer-mechanical |
          joe-bag-of-tricks:implementer | joe-bag-of-tricks:implementer-complex,
          chosen per SKILL.md Model Selection]):
  description: "Implement Task N: [task name]"
  # No model param — the agent definition pins its own model and reasoning effort.
  prompt: |
    You are implementing Task N: [task name]

    Read your task brief first: [BRIEF_FILE]
    It contains the full task text from bd (title, description, design, notes).

    Work from: [directory]
    Write your full report to: [REPORT_FILE]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Task-specific instructions

    [Anything that overrides or extends the contract for this task only — e.g. "TDD is
    required for this task", a test command that isn't discoverable, a plan-mandated
    file layout. Omit this section when there is nothing to add.]

    Your operating contract is the preloaded `implementer-contract` skill. Follow it:
    stay in scope, ask before guessing, escalate rather than improvise, self-review,
    and report in the contract's format.
```

**Discovered work:** the contract tells the implementer to report out-of-scope findings in its
report rather than fixing them. Creating beads for those findings is the controller's job.
