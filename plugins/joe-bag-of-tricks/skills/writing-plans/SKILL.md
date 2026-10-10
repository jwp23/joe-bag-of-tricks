---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Also use when entering or already in plan mode — all planning in this project goes through bd (beads) issue hierarchies.
argument-hint: "[spec or requirements]"
---

# Writing Plans

## Overview

Decompose features into bite-sized implementation tasks tracked in bd (beads), for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and the exact test, and that they will make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

## Plan Mode Integration

When you are in plan mode (entered via `EnterPlanMode` or `/plan`), this skill defines what "planning" means in this project. Do NOT write a freeform plan file — create the bd issue hierarchy described below instead.

**Workflow in plan mode:**

1. Follow this skill's full process: create epic (if needed), scope check, file structure, create tasks in bd, run self-review
2. Verify the hierarchy exists: `bd children <epic-id> --json` must show tasks before proceeding
3. Write a brief summary to the plan file referencing the bd hierarchy: epic ID, feature breakdown, task count, and key dependencies
4. Call `ExitPlanMode` to present the plan for approval
5. After approval, proceed to execution via the method chosen at the handoff (`ExitPlanMode` is the plan-review gate in plan mode)

**The bd hierarchy IS the plan.** The plan file is just a human-readable summary pointing to it.

**Red flags — you are doing it wrong if:**
- You are writing implementation steps directly in the plan file instead of bd
- You call `ExitPlanMode` without any `bd create` commands having run
- You skip straight to coding after plan approval without invoking subagent-driven-development or executing-plans

## Input

This skill receives an **epic ID** from the brainstorming skill. The epic already has feature/bug children representing components or subsystems.

**Prerequisite check:** If there is no design spec and the user is asking to brainstorm, design, or explore a feature idea, invoke the brainstorming skill first. Writing-plans decomposes an existing design into tasks — it does not replace the design phase.

If starting without an epic (e.g., ad-hoc planning with an existing spec or clear requirements), create one first:
```bash
bd create "<project name>" -t epic --description="<summary>" \
  --spec-id="docs/designs/<topic>.md" --json
```

The plan argues from the spec, so the spec travels with it: `--spec-id` points the epic at the
living design doc, and executors read both. If no design doc covers this area, say so on the
epic — rulings made without one are provisional.

Review the existing hierarchy before creating tasks:
```bash
bd children <epic-id> --json
```

## Scope Check

If the epic covers multiple independent subsystems, it should have been broken into sub-project epics during brainstorming. If it wasn't, suggest breaking this into separate epics — one per subsystem. Each epic should produce working, testable software on its own.

## Global Constraints

Capture the spec's project-wide requirements — version floors, dependency limits, naming and copy rules, platform requirements — on the **epic** so every task inherits them:

```bash
bd update <epic-id> --design="## Global Constraints
- <one line each, exact values copied verbatim from the spec>"
```

Every task's requirements implicitly include these. Implementers and reviewers read the epic's constraints alongside each task, so a plan-mandated rule (e.g. "Node >= 24", "no new dependencies") is enforced without repeating it in every task.

## Review Focus

The spec is a vision document: it says what the software must do, not everything it will meet, and its silence on an input is not permission for that input to break the program. With the spec in front of you, list the five input classes or failure modes it implies but no task's tests exercise that are most likely to bite a person using this software — one line each, naming the input or condition and the behavior a reasonable person would expect, most likely first. Record the list on the **epic**, in the same `--design` field as Global Constraints (`bd update --design` replaces the field, so write both sections in one update):

```bash
bd update <epic-id> --design="## Global Constraints
- <one line each, exact values copied verbatim from the spec>

## Review Focus
- <input or condition> — <what a reasonable person expects>"
```

Then, for each line, add the test that pins it to the task that owns the code, in that task's own step style. The final reviewer reads this section verbatim and checks each line deliberately.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

**Survey by delegation, read by the slice.** Task designs need exact signatures and line anchors, but that does not mean reading whole files into the planning context — a full read of one large module can cost more resident tokens than the entire task hierarchy you're writing, and it is re-billed on every turn after. Dispatch an Explore agent to return the survey (module map, public signatures, relevant line numbers), then Read only the specific functions your task designs will prescribe edits to, with offset/limit. The survey tokens die with the subagent; only the load-bearing slices enter your context.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. When drawing task boundaries in bd: fold setup, configuration, scaffolding, and documentation steps into the task whose deliverable needs them; split only where a reviewer could meaningfully reject one task while approving its neighbor. Each task ends with an independently testable deliverable.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Creating Tasks in bd

For each feature/bug child of the epic, create task issues as children. Use `--description` for summary and acceptance criteria, `--design` for detailed TDD steps with code.

```bash
bd create "<task title>" -t task \
  --parent <feature-id> \
  --description="<summary>. Acceptance: <criteria>" \
  --design="$(cat <<'EOF'
## Files
- Create: `exact/path/to/file.ext`
- Modify: `exact/path/to/existing.ext:123-145`
- Test: `tests/exact/path/to/test.ext`

## Interfaces
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter and return types. A task's implementer sees only their own task; this block is how they learn the names and types neighboring tasks use.]

## Steps

### Step 1: Write the failing test

```lang
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

### Step 2: Run test to verify it fails

Run: `test-command tests/path/test.ext::test_name -v`
Expected: FAIL with "function not defined"

### Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.ext`

One line on the approach when the signature and the test leave a choice
(which library call, which data structure); a code block only for an
algorithm they do not determine.

### Step 4: Run test to verify it passes

Run: `test-command tests/path/test.ext::test_name -v`
Expected: PASS

### Step 5: Commit

```bash
git add tests/path/test.ext src/path/file.ext
git commit -m "feat: add specific feature"
```
EOF
)" --json
```

### Task Dependencies

Set inter-task dependencies when one task must complete before another can start:

```bash
bd dep <blocker-task-id> --blocks <blocked-task-id>
```

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing
from it. That is the whole requirement: unambiguous, not complete. Each kind
of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the
  spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the
  file it lives in, and the specific values the spec pins. The implementer
  writes the body. A body appears only for an algorithm the signature and
  tests do not determine, or for exact copy the spec fixes.
- **A verification step:** the command to run and the output that means it
  passed.
- **A reference to another task:** that task's Interfaces block says what
  to use; the design does not repeat that task's code. Tasks are dispatched
  to fresh subagents that may run out of order.

A plan is the set of decisions the implementer cannot make alone. A plan
longer than the code it describes has written the code instead. Lines that
decide nothing are the opposite failure, and the self-review catches both:
"TBD", "handle edge cases", "add appropriate validation", "write tests for
the above", a type or function no task defines, and "invoke the X skill" or
"run `/command`" — tasks are dispatched to implementer subagents that have
no Skill tool, so that step is impossible as written. Name the procedure's
file instead ("follow the procedure in `<path>`"), and where that file will
not be readable from the worktree, write out the steps the task actually
needs.

When a task involves a technical choice (tool selection, patterns, library choices), invoke **record-decision** yourself while planning — never as a step in the task.

## Self-Review

After creating all tasks, look at the spec with fresh eyes and check the bd hierarchy against it. This is a checklist you run yourself — not a subagent dispatch.

1. **Spec coverage:** Skim each section/requirement in the spec. Can you point to a bd task that implements it? List any gaps and fill them.
2. **Step scan:** Every step must let the implementer write exactly one reasonable thing, and no step may carry more than that: a line that decides nothing is a gap, a function body the signature and tests already determine is a transcript. Fix both.
3. **Type consistency:** Do the types, method signatures, and property names in later tasks match what earlier tasks define? The per-task Interfaces blocks are where you verify this — a function called `clearLayers()` in one task but `clearFullLayers()` in another is a bug.
4. **Review Focus:** For each input class or failure mode the spec implies, is there a task whose tests exercise it? The five uncovered ones most likely to bite a person go in the epic's Review Focus section, and each line there gets its test added to the owning task. An empty section means you checked and found none, not that you skipped the check.
5. **Proportion:** Compare the hierarchy's design fields, taken together, to the spec's length. A plan several times longer than the spec it implements is a transcript of the program, not a plan. If code blocks are most of it, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous.
6. **Sibling coverage:** for each bug-shaped task, does the hierarchy state whether other surfaces of the same concept were checked, or which tasks share a cause?

## Execution Handoff

After the hierarchy is created and self-reviewed, show it to your human
partner (`bd children <epic-id> --pretty`) to read. Approving the idea, the
design, or the feature decomposition did not approve task designs they have
not seen. If they have already explicitly supplied an execution method, ask
them to review the hierarchy and confirm it captures what they want; wait
for that review before implementation, then use the preserved method.
Otherwise, ask them to review it and choose an execution method before
implementation. In plan mode, `ExitPlanMode` is this gate.

**When no execution method has already been supplied:**

**"Tasks created under epic `<epic-id>`. Please review the hierarchy. Which execution approach would you prefer?**

- **Subagent-driven** - A fresh subagent implements each task and a fresh reviewer checks it before the next one starts, then a whole-branch review at the end. Most thorough; costs a fresh context per task and per review.
- **Native** - I implement every task myself in this session, then one fresh reviewer on the most capable model checks the whole branch. Cheapest and fastest; no independent review until the end. Runs well with a mid-tier session model, since the plan carries the design.

**For this plan I recommend <one of the two>, because <one sentence from the plan: how much the tasks depend on each other's interfaces, how many there are, what a shipped mistake would cost>. Does the hierarchy capture what you want, and which approach should we use?"**

**When an execution method has already been supplied:**

**"Tasks created under epic `<epic-id>`. Please review the hierarchy. Does it capture what you want?"**

**If Subagent-driven chosen:**
- **REQUIRED SUB-SKILL:** Use subagent-driven-development

**If Native chosen:**
- **REQUIRED SUB-SKILL:** Use executing-plans
