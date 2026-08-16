# Authoring Workflow

How editing a `SKILL.md` or an `agents/*.md` file is made to reliably invoke the authoring
discipline this repo requires, instead of skipping it.

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
changes — a new rule, a new bucket, a new gate, or a relaxation of one.

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
