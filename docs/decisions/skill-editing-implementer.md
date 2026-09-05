# A Repo-Local skill-editing-implementer Preloads writing-skills + writing-agents

## Decision

- Add `.claude/agents/skill-editing-implementer.md` — authoring-only, project-scoped, **not**
  shipped in any plugin (see `docs/architecture.md`'s shipped-vs-authoring split). Same tier as
  `plugins/joe-bag-of-tricks/agents/implementer.md` (`model: sonnet`, `effort: medium`, same
  tool allowlist), but its `skills:` frontmatter adds `writing-skills` and `writing-agents` to
  the `implementer-contract` every implementer tier already carries.
- Beads whose target files are a `SKILL.md` or a file under a plugin's `agents/` dispatch to
  this agent instead of `implementer`. It exists specifically so the eight sibling
  skill/agent-editing beads queued behind this one (`agents/branch-shepherd.md`,
  `skills/using-skills`, `skills/authoring-beads`, `skills/systematic-debugging`,
  `skills/dispatching-parallel-agents`, `skills/subagent-driven-development`,
  `skills/implementer-contract`, `skills/brainstorming`, `skills/finishing-a-development-branch`)
  get the authoring discipline of `.claude/rules/authoring-skills-and-agents.md` preloaded
  rather than pointed to.
- Rejected alternative 1: **granting implementers the Skill tool.** Rejected because it widens
  every implementer dispatch's tool surface to whatever skill happens to auto-trigger mid-task,
  not just the two authoring skills this agent needs — the tight roster is what keeps a generic
  implementer scoped, and loosening it for one recurring need would loosen it for all of them.
- Rejected alternative 2: **status-quo per-brief "Read the SKILL.md" pointers**, the mechanism
  `implementer-contract` already falls back to for a one-off named procedure (see
  `plan-steps-name-procedures-not-skills.md`). Rejected as the *general* fix for this recurring
  need, for the same reason that decision gives for not preloading a per-task procedure into
  `skills:`, read the other way: "Preloading is the right tool for text that applies to all
  dispatches... It stays available for a future skill that genuinely does apply to every
  implementer dispatch; that would be its own decision." Eight of the next eight beads editing a
  skill or agent file is exactly that case, and per-brief pointers are fragile against it in a
  way preloading is not — each of the eight briefs would have to independently and correctly
  name the same two files, with no guard against a brief that forgets, and the only recorded
  precedent (`joe-bag-of-tricks-zfi.6`) worked only because the implementer happened to notice
  the skill was a file in the repo being edited.

## Rationale

- Reuses the mechanism `implementer-contract-as-preloaded-skill.md` already proved — `skills:` as
  a YAML sequence of bare skill names, injected verbatim and free by the harness — rather than
  re-litigating it. Precondition checked directly, not assumed: neither `writing-skills` nor
  `writing-agents` carries `disable-model-invocation: true` or `user-invocable: false`, the flag
  that decision found silently breaks preloading.
- **Verified, not assumed, this round**: unprefixed skill names in a repo-local `.claude/agents/`
  agent's `skills:` list resolve across the plugin boundary to `plugins/joe-bag-of-tricks/skills/*`.
  Proved by dispatching `.claude/agents/skill-editing-implementer` via a fresh headless
  `claude -p` session and reading its `--debug-file` log for `Preloaded skill '<name>'` lines —
  the authoritative instrument for the load question, since a quoting canary alone can return a
  false-negative "ABSENT" for a skill the debug log shows was loaded (see the task report for the
  full RED/GREEN transcript). A `joe-bag-of-tricks:`-prefixed form was raised as an alternative
  but never itself verified to be accepted in a `skills:` list, so the committed agent keeps the
  proven bare-name form. Re-run this same `claude -p --debug-file` + grep method to re-prove it
  after any future change to the harness's skill-resolution behavior.
- Model tier unchanged from `implementer`: skill/agent edits are the same ordinary multi-file
  integration work implementer already handles, so nothing here calls for
  `implementer-mechanical`'s mechanical-only ceiling or `implementer-complex`'s design-judgment
  tier; a task that needs one escalates through the existing ladder
  (`orchestration-model-tiering.md`).
- Roster-gating check (read `check-context-budget.sh` itself, not just the roster-budget
  decision, per that decision's own instruction): `AGENTS_DIR` is hardcoded to
  `plugins/joe-bag-of-tricks/agents`, so a `.claude/agents/` file is outside the tier-2 glob and
  the gate does not count this agent's roster line — it ran unchanged, no `BUDGET` change needed.
  This is a real gap: the harness injects a project-level `.claude/agents/` entry into the same
  roster `<system-reminder>` as a plugin agent, so the cost is real and merely unmeasured.
  Left unfixed deliberately — widening `AGENTS_DIR` is its own scope decision — and recorded as
  discovered work in the task report.
- `docs/customizations.md` needs no new row: its scope is plugin payload plus named repo-root
  files, and `.claude/` sits outside that, same as every other file under `.claude/`.
- Decided 2026-09-05, task `joe-bag-of-tricks-dtr.9`.

## Revisit Trigger

- `check-context-budget.sh`'s `AGENTS_DIR` is widened to include `.claude/agents/` — this
  agent's roster line then becomes real gated surface and needs its own budget accounting.
- A ninth or later skill/agent-editing bead needs a different model tier (e.g. a skill edit that
  is actually a design-judgment call) — that dispatch escalates through the existing ladder
  rather than changing this agent's pinned tier.
- `writing-skills` or `writing-agents` gains `disable-model-invocation: true` for an unrelated
  reason — this agent's preload would silently stop working, per the mechanism's documented
  failure mode, and would need to be caught the same way it was caught here: reading the
  frontmatter, not assuming.
