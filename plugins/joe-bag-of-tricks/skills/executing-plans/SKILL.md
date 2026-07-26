---
name: executing-plans
description: Use when you have a bd task hierarchy to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load epic, review tasks critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that this skill works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Tasks
1. Ensure an isolated workspace: use using-git-worktrees to create one or verify the existing one
2. List all tasks under the epic:
   ```bash
   bd children <epic-id> --json
   ```
3. For each feature/bug, list its tasks:
   ```bash
   bd children <feature-id> --json
   ```
4. Read task details (description, acceptance criteria, design steps):
   ```bash
   bd show <task-id>
   ```
5. Review critically - identify any questions or concerns about the tasks
6. If concerns: Raise them with your human partner before starting
7. If no concerns: Proceed to execution

### Step 2: Execute Tasks

For each task:
1. Claim the task:
   ```bash
   bd update <task-id> --claim
   ```
2. Read the task's design field for step-by-step instructions:
   ```bash
   bd show <task-id>
   ```
3. Follow each step exactly (tasks have bite-sized steps)
4. Run verifications as specified
5. Close the task:
   ```bash
   bd close <task-id> --reason "<what was done>"
   ```

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Task has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates tasks based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review tasks critically first
- Follow task design steps exactly
- Don't skip verifications
- Reference skills when task says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

