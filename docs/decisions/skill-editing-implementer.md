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

- `implementer-contract-as-preloaded-skill.md` already proved `skills:` frontmatter injects a
  named skill's full text into a subagent's context with zero tool calls, verified with a
  canary-phrase probe. This decision reuses that mechanism rather than re-litigating it: same
  `skills:` list shape (a YAML sequence of bare skill names), same reason it works (harness
  injection is free and verbatim; a markdown link in an agent body is not expanded).
- `writing-skills` and `writing-agents` carry neither `disable-model-invocation: true` nor
  `user-invocable: false` — confirmed by reading their frontmatter directly. The preloaded-skill
  decision above found `disable-model-invocation: true` silently breaks preloading (the probe
  returned the absence sentinel with it set), so this was a real precondition to check, not a
  formality.
- Model tier: unchanged from `implementer`. Skill/agent edits are ordinary multi-file integration
  work of the same difficulty implementer already handles — wiring a `skills:` list, following an
  established frontmatter shape, applying documented review checklists. Nothing about editing a
  `SKILL.md` calls for `implementer-mechanical`'s mechanical-only ceiling or
  `implementer-complex`'s design-judgment tier; a task that does escalates through the existing
  ladder exactly as it would from `implementer` (`orchestration-model-tiering.md`).
- Roster-gating check (read `.claude/scripts/check-context-budget.sh`, not just the roster-budget
  decision, per that decision's own instruction that the script decides what it counts):
  `AGENTS_DIR` is hardcoded to `${PLUGIN_DIR}/agents` (`plugins/joe-bag-of-tricks/agents`), and
  the tier-2 loop globs only that directory. `.claude/agents/skill-editing-implementer.md` is
  outside it, so `check-context-budget.sh` does not count this agent's roster line at all — the
  gate ran unchanged (see the implementation report) and needed no `BUDGET` change. This is a
  gap, not a feature: the real harness injects a project-level `.claude/agents/` entry into the
  same Agent-tool roster `<system-reminder>` as a plugin agent (the capture procedure in
  `agent-roster-in-the-context-budget.md` does not distinguish the two), so this agent's line is
  real per-session cost that the gate is structurally blind to. Recorded here rather than
  silently fixed, because widening `AGENTS_DIR` to also glob `.claude/agents` is itself a
  decision — it would begin gating every future authoring-only agent, a scope the gate has never
  had — and is left to the orchestrator/Joe rather than made unilaterally inside this bead.
- `docs/customizations.md` needs no new row: its own scope statement covers "Plugin payload...
  nested under `plugins/joe-bag-of-tricks/`" plus repo-root files it already tracks by name;
  `.claude/` is authoring-only and outside the manifest's stated scope, matching every other
  file already under `.claude/agents/`-adjacent dirs (none of which has a manifest row).
- Live-dispatch verification — "a dispatched instance verifiably has all three skills loaded" —
  is deferred to the orchestrator after merge: the Agent roster is fixed at session start, so a
  brand-new agent added in this session's own worktree is not dispatchable from the session that
  created it. What is verified here is static: the `skills:` entries resolve to real,
  correctly-named skills that exist on disk and are preloadable (not gated behind
  `disable-model-invocation`), matching how `implementer-contract-as-preloaded-skill.md` itself
  was eventually reproved (a real probe dispatch, run once the mechanism was in a position to be
  dispatched).
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
