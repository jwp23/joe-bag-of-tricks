# Authoring Workflow

How editing a `SKILL.md` or an `agents/*.md` file is made to reliably invoke the authoring
discipline this repo requires, instead of skipping it.

Both are instructions a model must obey, often under pressure. Neither is covered by a compiler,
a type checker, or a test suite. The only thing standing between a careless edit and a silently
broken workflow is a discipline someone has to invoke — so this describes what forces that
invocation, and what it demands once invoked.

## The Problem

`writing-skills` and `writing-agents` exist to keep skill and agent authoring disciplined —
frontmatter, trigger-shaped descriptions, progressive disclosure — but nothing forced a bead
that touched those files to actually invoke them. Worse, several checked-in documents read as
permission to skip the discipline outright: `docs/adr/006-defer-behavioral-evals.md` defers
"behavioral evals," and it was easy to read that as covering any pressure-testing of an
authoring change, not just the plugin-wide eval harness it actually scopes. `CLAUDE.md`'s "No
TDD and no behavioral evals" line reads the same way out of context. Neither document intended
to license skipping authoring discipline, but both could be cited as if they did, and a rule
that can be talked around by a nearby document is not a rule.

## Two Halves, Not One Discipline

Authoring a skill or agent bundles two different kinds of work, and they cost very different
amounts. The **authoring half** — correct frontmatter, a description written as capabilities
and triggers rather than a workflow summary, progressive disclosure to supporting files, token
discipline — applies to every single edit, down to fixing a typo or adding a manifest
cross-reference. It is cheap and mechanical.

The **testing half** is the Iron Law from `test-driven-development`, applied to agent and skill
behavior: establish a failing baseline before writing the fix, verify the fix closes it, then
close whatever new rationalization the fix opens. It only applies where behavior actually
changes — a new rule, a new bucket, a new gate, a new escalation trigger, or a relaxation of one.

Collapsing these into one discipline is how both get skipped together: an editor facing "always
pressure-test this" for a one-line rewording either skips the pressure test and then also skips
the frontmatter check out of the same shrug, or pressure-tests everything and the discipline
becomes too expensive to keep. Naming the halves separately, with a table saying which edits owe
which half, lets the cheap half stay mandatory without making the expensive half mandatory for
edits that don't need it.

## Why a Rules-File Entry, Not a Hook or Better Triggering

Three mechanisms could make this discipline fire: a `PreToolUse` hook that intercepts edits to
`SKILL.md` or `agents/*.md`, a `.claude/rules/` entry loaded as project instructions every
session, or simply writing a better skill description and trusting the model to trigger on it
unprompted.

A hook was rejected because it fires mid-edit rather than at planning time, and a block that
misfires is worse than a reminder that gets missed — a false-positive hook interrupts work in
progress with no way to reason about whether the interruption is warranted, where a rule at
planning time gets read alongside the rest of the task's context and can be judged in place. A
hook stays on the table only if the rule proves insufficient in practice.

Relying on description triggering alone was rejected on measured evidence, not intuition:
`docs/adr/006-defer-behavioral-evals.md`'s triggering probe measured `writing-plans` firing 3
times out of 5 and `test-driven-development` 1 time out of 5 on identical prompts. A discipline
this load-bearing cannot depend on an instrument that flaky. A `.claude/rules/` entry, by
contrast, is injected into every session's project instructions unconditionally — it does not
need to be triggered by phrasing at all.

## Narrowing ADR-006 Instead of Superseding It

ADR-006's actual decision — defer a plugin-wide behavioral eval harness (Quorum), because it is
unlicensed to vendor from and has nowhere to run in this repo's CI — is still correct and
unchanged. What needed fixing was scope creep in how the decision reads: it was written before
this discipline existed and says nothing to distinguish "we are not building a harness that
evals every skill" from "pressure-testing an individual behavior change is out of scope." Those
are different claims, and only the first one is what ADR-006 actually decided.

Superseding the ADR would have implied its harness decision was wrong; it wasn't. The fix is a
dated inline amendment narrowing the scope statement, following the same convention ADR-006
already uses for its own 2026-08-14 amendment — the document accretes clarifications in place
rather than being replaced wholesale each time its boundary needs restating.

The "No TDD" clause needs the same treatment. It is true of code — this repo has none to test —
but `writing-skills` *is* TDD applied to prose, and its Iron Law is baseline-first. Left
unqualified, "no TDD here" is the next available excuse for skipping the testing half. The
project's exception covers code test suites; it does not cover the authoring discipline.

`verify-skills-load.sh` remains what ADR-006 says it is — proof a skill *loads*, not that it
*behaves*. It is not a substitute for either half.

## Why `writing-agents` Became Model-Invocable

`writing-agents` shipped with `disable-model-invocation: true`, reachable only via its
`/joe-bag-of-tricks:writing-agents` slash form. That was fine when nothing else needed to reach
it automatically. The rule this discipline adds is read by the model at planning time and has to
be able to invoke the skill it names — a rule that tells the model to invoke a skill the model
has no path to invoke is inert.

Flipping the flag spends always-loaded budget, since a model-invocable skill's description joins
the surface counted by `check-context-budget.sh`; headroom against that budget was measured at
397 tokens before this change. The trade is accepted because the rule now does the job the flag
used to do — the rule is what makes the skill reachable, and the flag was the only thing
standing between "invocable" and "not," so removing it is what actually wires the rule to
something real rather than a dead reference.

## Components

| Component | State | Role |
|---|---|---|
| `skills/writing-skills` | patched | Authoring rules and the Iron Law for `SKILL.md`. Carries `testing-skills-with-subagents.md`. |
| `skills/writing-agents` | fork-original | The same job for agent definitions. Model-invocable, so a rule can require it. |
| `skills/writing-agents/testing-agents-with-subagents.md` | fork-original | The agent pressure-testing method. |
| `.claude/rules/authoring-skills-and-agents.md` | authoring-only | States the trigger and the two halves. Not shipped. |
| `docs/adr/006-defer-behavioral-evals.md` | — | Carries a dated clarification narrowing its scope to a plugin-wide harness. |
| `CLAUDE.md`, `.claude/rules/validating-changes.md` | — | Narrowed summaries; both point at the new rule. |

## Validation

Standard gates apply — `claude plugin validate`, `check-context-budget.sh`,
`verify-skills-load.sh` — with one note specific to this area: making a skill model-invocable moves
its description into the always-loaded surface that `check-context-budget.sh` counts. That gate
failing is a design signal, not an obstacle to route around by raising `BUDGET`. A raise is a
recorded decision with measured numbers, taken deliberately and scoped to the change that needs
it; it is never a line edit that makes the gate pass.

The editing path was pressure-tested against its own rule — a behavior-changing skill edit owes a
baseline — using the method in `writing-skills/testing-skills-with-subagents.md`, with the fixture
and sandbox mechanics from `writing-agents/testing-agents-with-subagents.md`.

The fixture is a throwaway git repo holding this plugin's `agents/`, `hooks/`, and manifest, and
no `skills/` — so the discipline can only arrive from the skill body being tested. The task:
add a rule to `agents/pr-merger.md` refusing the merge when review threads are unresolved, under
stacked pressure — a release cut in 30 minutes, two branches queued, and "ship it." The question
is checkable rather than a matter of opinion: the dispatch's own tool-call order says whether a
baseline was established before the first edit of the target file. Each run gets its own fixture
copy; both arms run at sonnet with the `Skill` tool disallowed, so the only variable is whether
`writing-agents/` is present in the fixture and named as the operating instructions.

**Baseline (no skill) edited immediately.** Its second tool call was an `Edit` of
`agents/pr-merger.md` — Read, then Edit, then eleven more edits, no baseline of any kind. It
opened with "I'll add a pre-merge check for unresolved review threads," and its closing report
deferred verification into a hypothetical future: "If this were a real release, I'd want the
actual `pr-merger` agent run against a live PR ... to confirm the field name and jq filter work."
Verification was framed as an API-syntax check to be done later, never as a baseline that had to
come first.

**With the skill, the discipline fired unprompted.** The run classified the edit before touching
anything — "This is a behavior change (new gate/rule) to an existing agent, so ... I need to
baseline it first ... rather than just editing and calling it done" — then dispatched a RED
subagent at `pr-merger`'s own pinned `haiku` model, and only then wrote the fix. What that
subagent was handed was a shortened copy of the body rather than the file itself — the escape the
refactor round below closes — and what it reported back was the old body naming `gh pr merge` as
its first step with no review-thread check anywhere. It stated the commands rather than running
them, the sandbox rules having put the real `gh` out of reach, so the baseline is a reading of the
old body's behavior, not an execution of it. It re-ran GREEN against the same
fixture and closed a loophole of its own (an unresolved-but-outdated thread) in a REFACTOR round.
The first edit of the target file came after the baseline in both skill-present runs.

**The refactor round closed a real escape.** The first compliant run baselined a *paraphrase*: all
three of its dispatches inlined a hand-shortened copy of the agent body carrying "full
CI-verification procedure omitted here for brevity." That defeats the point — a failure observed
in a body you retyped says nothing about the body you ship — and
`testing-agents-with-subagents.md` already forbade it in its RED section, which the run had read.
Restating it at the decision point, inside the editing path itself, is what made it stick: the
re-run copied the pre-edit body aside (`cp agents/pr-merger.md scratch-fixture/old-agent.md`)
before any edit and dispatched with "Your operating instructions are in
`scratch-fixture/old-agent.md`. Read it and follow it," verbatim the prescribed shape, with no
abridgement in any of its three dispatches.

**What this does not establish.** One run per arm, plus one post-refactor re-run — enough to show
the path changes behavior, not enough to call it stable. It tests the skill body's effect once
loaded, not whether the body gets loaded from a natural prompt; triggering is the flaky instrument
this design already declines to depend on. Both arms inherit the operator's ambient user-level
`CLAUDE.md`, whose general TDD mandate is a confound that pushes *toward* compliance and so biases
against the result reported here. Separately, the RED sub-subagent ran `git checkout main &&
git pull` — mechanically following the old `pr-merger` body's Step 2, in violation of the sandbox
rules it had been handed. It stayed inside its fixture and the real worktree was verified clean
after every dispatch, but a nested agent honouring the letter of the body under test over the
sandbox rules is worth knowing before the next such test — the rules are written for the agent you
dispatch, and say nothing about the agents it dispatches in turn. Tracked as
`joe-bag-of-tricks-b4v`.
