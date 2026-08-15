# Implementer Contract Lives in One Preloaded Skill

## Decision

- The shared SDD implementer contract — scope boundaries, "you do not dispatch
  subagents", code organization, escalation, self-review, report format — lives
  in exactly one file: `plugins/joe-bag-of-tricks/skills/implementer-contract/SKILL.md`.
- The three implementer agents (`implementer-mechanical`, `implementer`,
  `implementer-complex`) pull it in with a `skills:` list naming
  `implementer-contract` in their frontmatter. Each agent body keeps only what
  differs: the model/effort pin and the paragraph saying which tier it is.
  167 lines each → 17.
- `subagent-driven-development/implementer-prompt.md` no longer restates the
  contract. It is a dispatch envelope: which task, brief path, report path,
  working directory, context, and task-specific overrides.
- The contract skill carries **no** `disable-model-invocation` and no
  `user-invocable: false` — see Rationale.

## Rationale

- Four near-identical copies of a 155-line contract meant every edit was a
  four-way transcription, guarded only by a "edit them together" clause in
  `docs/customizations.md`. That guard is now unnecessary: there is one copy.
- Agent frontmatter and body are injected as the subagent's system prompt, but a
  markdown link in that body is *not* expanded. A "see the contract file"
  reference would have cost a Read round-trip and a path the agent cannot resolve
  reliably once the plugin is installed elsewhere. `skills:` is the mechanism
  Claude Code actually provides for injecting shared text into an agent's context.
- `skills:` is written as a YAML **sequence**, the only form the sub-agents
  documentation shows. A bare scalar (`skills: implementer-contract`) is coerced
  today but is undocumented, and the failure mode is silent: a listed skill that
  cannot be resolved is skipped with only a debug-log warning, so a parser that
  tightened to sequence-only would strip the whole contract from all three
  implementers with no error anywhere in the pipeline.
- Verified empirically before adopting, with a throwaway probe plugin (a canary
  phrase in a preloaded skill, an agent instructed to use no tools):
  - with `skills:` → the agent quoted the phrase, zero tool calls;
  - without `skills:` → the agent returned the absence sentinel.
  Confirmed again against the real artifacts: `implementer-mechanical` quoted a
  verbatim sentence from the contract with zero tool calls. Re-proved after the
  move to the sequence form; the full probe transcript is on
  `bd show joe-bag-of-tricks-bq7`. To re-run it, the probe MUST dispatch a real
  subagent — `claude -p --agent implementer` sets the agent for the *main*
  session and does not exercise subagent preloading at all, returning the
  absence sentinel whatever `skills:` says.
- **`disable-model-invocation: true` breaks the preload.** The same probe with
  that flag added returned the absence sentinel. A hidden-from-the-model skill is
  not preloadable, so the contract skill is an ordinary skill and pays ~50 tokens
  of description in every session. That is the price of the mechanism working.
- Per-dispatch tokens drop roughly in half for the contract text: it used to
  arrive twice (once as the agent's system prompt, once restated in the dispatch
  prompt). It now arrives once, injected by the harness, so the controller no
  longer emits it at all.
- The contract stayed in the agent-side artifact rather than the dispatch prompt
  because harness injection is free and verbatim, while a prompt template is
  copied by the controller each dispatch — costing output tokens and inviting
  paraphrase drift.
- Content unchanged: the skill body is the verbatim contract text from
  `agents/implementer.md`, plus a two-line header. This was deduplication, not a
  rewrite.
- Decided 2026-08-14 while closing joe-bag-of-tricks-bq7.
