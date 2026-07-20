---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Also use when entering or already in plan mode — all planning in this project goes through bd (beads) issue hierarchies.
argument-hint: "[spec or requirements]"
---

# Writing Plans

## Overview

Decompose features into detailed, bite-sized implementation tasks tracked in bd (beads). Each task contains everything an engineer needs: which files to touch, code, testing steps, how to verify. DRY. YAGNI. TDD. Frequent commits.

Assume the implementing engineer is skilled but knows almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

## Plan Mode Integration

When you are in plan mode (entered via `EnterPlanMode` or `/plan`), this skill defines what "planning" means in this project. Do NOT write a freeform plan file — create the bd issue hierarchy described below instead.

**Workflow in plan mode:**

1. Follow this skill's full process: create epic (if needed), scope check, file structure, create tasks in bd, run self-review
2. Verify the hierarchy exists: `bd children <epic-id> --json` must show tasks before proceeding
3. Write a brief summary to the plan file referencing the bd hierarchy: epic ID, feature breakdown, task count, and key dependencies
4. Call `ExitPlanMode` to present the plan for approval
5. After approval, proceed directly to execution via subagent-driven-development

**The bd hierarchy IS the plan.** The plan file is just a human-readable summary pointing to it.

**Red flags — you are doing it wrong if:**
- You are writing implementation steps directly in the plan file instead of bd
- You call `ExitPlanMode` without any `bd create` commands having run
- You skip straight to coding after plan approval without invoking subagent-driven-development

## Input

This skill receives an **epic ID** from the brainstorming skill. The epic already has feature/bug children representing components or subsystems.

**Prerequisite check:** If there is no design spec and the user is asking to brainstorm, design, or explore a feature idea, invoke the brainstorming skill first. Writing-plans decomposes an existing design into tasks — it does not replace the design phase.

If starting without an epic (e.g., ad-hoc planning with an existing spec or clear requirements), create one first:
```bash
bd create "<project name>" -t epic --description="<summary>" --json
```

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

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. When drawing task boundaries in bd: fold setup, configuration, scaffolding, and documentation steps into the task whose deliverable needs them; split only where a reviewer could meaningfully reject one task while approving its neighbor. Each task ends with an independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
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

### Step 3: Write minimal implementation

```lang
def function(input):
    return expected
```

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

## No Placeholders

Every task design must contain the actual content an engineer needs. These are **plan failures** — never write them into a bd task:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — tasks are dispatched to fresh subagents that may run out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in task designs (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits
- When making technical choices (tool selection, patterns, library choices), invoke **record-decision**

## Self-Review

After creating all tasks, look at the spec with fresh eyes and check the bd hierarchy against it. This is a checklist you run yourself — not a subagent dispatch.

1. **Spec coverage:** Skim each section/requirement in the spec. Can you point to a bd task that implements it? List any gaps and fill them.
2. **Placeholder scan:** Check every task design for the red flags in the "No Placeholders" section above. Fix them.
3. **Type consistency:** Do the types, method signatures, and property names in later tasks match what earlier tasks define? The per-task Interfaces blocks are where you verify this — a function called `clearLayers()` in one task but `clearFullLayers()` in another is a bug.

## Execution Handoff

After all tasks are created and reviewed, proceed to execution:

**"Tasks created under epic `<epic-id>`. Moving to subagent-driven execution."**

**REQUIRED SUB-SKILL:** Use subagent-driven-development — fresh subagent per task + two-stage review (spec compliance, then code quality).
