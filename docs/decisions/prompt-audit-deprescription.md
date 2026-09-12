# Prompt Audit: De-prescribe Skills and Agents, Diverging From Upstream Where Needed

## Decision

- Skill and agent bodies are audited against the current model generation with Anthropic's
  `prompt-audit` procedure (the `claude-api` skill, `shared/prompt-audit.md`), and dated
  prompting patterns it identifies are removed: pressure language with no reason beside it,
  prohibition clusters with no provenance, incident archaeology standing in for a rule,
  procedural how-to-work lines, and duplicated rules that disagree with the project's own
  instruction files.
- **A `patched` upstream file is edited for prompt quality when the audit finds a dated pattern
  in it.** Improving the plugin outranks minimizing sync friction. Each such edit gets a note in
  `docs/customizations.md` naming the hunk and saying "keep the fork's line" so the next
  `/upstream-sync` resolves the conflict deliberately rather than by adopt-by-default.
  `vendored` files are still never edited in place; a vendored file with a finding is
  reclassified first or left alone.
- **The three implementer agents stay.** The audit's Group 4 check flagged them as near-duplicate
  specialists. They are kept because the roster form enforces two contract rules in code (the
  tool allowlist removes the Agent and Skill tools, so "no subagents" and "no Skill tool" are
  facts rather than prohibitions), pins per-tier `effort` (which the Agent tool cannot pass at
  dispatch), and makes the silently-inherited-model failure impossible. Only the tool-call count
  in `implementer-mechanical` was removed.
- **The SDD narration rule ("print nothing between tool calls in the routine loop") stays as
  written.** The audit found it disagreed with the global CLAUDE.md autonomous-runs rule ("one-line
  statuses between actions"); the resolution was to patch the global file to match the plugin,
  not the reverse.
- Findings the audit rated low, or that sit in upstream's discipline methodology
  (`writing-skills` "Bulletproofing Against Rationalization", `persuasion-principles.md`, the TDD
  and systematic-debugging Iron Law clusters), were recorded in the audit report and left alone.

## Rationale

- The audit's premise is documented model behavior, not taste: current models follow
  instructions closely enough that inflated emphasis over-triggers and an anxious register
  produces hedging output; prompts written for prior generations are often too prescriptive and
  reduce output quality; "don't narrate" text written against update-eager older models makes
  Claude Fable 5.1 under-narrate. Two of the findings were contradictions this repo's own
  instructions made visible: the always-injected `using-skills` body told the model to create
  TodoWrite todos while AGENTS.md forbids TodoWrite, and the implementer contract had drifted
  back to the exact procedural phrasing `goal-shaped-not-procedural-agent-instruction.md`
  measured as the worst arm.
- Measured, where the repo has an instrument: `using-skills` hook injection 2005 → 1587 tokens
  and always-loaded headroom 191 → 609 (`check-context-budget.sh`); the triggering probe ran at
  `--repeat 3` before and after the `using-skills` edit and the counts are in the PR. The probe is
  advisory by design (`docs/adr/006-defer-behavioral-evals.md`), so it is a signal that the trim
  did not obviously depress triggering, not a proof.
- Editing `patched` files was the maintainer's call, made 2026-09-11: sync friction is a
  bounded, per-sync cost paid by one person with a manifest to guide them, while a dated
  instruction in a shipped skill is paid on every load by every session. The adopt-by-default
  wording policy in `docs/customizations.md` still governs cosmetic and neutralization diffs; it
  does not require re-adopting an upstream line the audit removed.
- Re-run the audit at each model release. A line that is load-bearing on one generation is cruft
  on the next, and the migration guide's per-target checklist is also a removal checklist.

## Cost if wrong

If a removed booster or rationalization row was actually load-bearing, a skill under-triggers or a
discipline rule gets rationalized around. Both surface in ordinary use, and every removal is one
hunk in one commit, so a regression restores its line in its minimal form rather than the verbose
original. The patched-file edits cost one deliberate conflict resolution per upstream sync each.
