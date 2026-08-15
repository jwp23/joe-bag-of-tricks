# Trim Multi-Harness Prose from using-skills

## Decision

Remove the multi-harness prose from `plugins/joe-bag-of-tricks/skills/using-skills/SKILL.md` —
the file the SessionStart hook injects verbatim into every session — and delete the harness
reference files the manifest already claimed were gone.

Removed from the injected body:

- the "In Gemini CLI" activation paragraph and the "In other environments" line under
  *How to Access Skills*, leaving the `Skill`-tool sentence as the whole section
- the *Platform Adaptation* section, which pointed non-Claude-Code platforms at
  `references/codex-tools.md` and described a GEMINI.md tool-mapping load

Edited, not removed:

- the *Instruction Priority* list and its worked example now name CLAUDE.md and AGENTS.md only.
  `GEMINI.md` is dropped; **AGENTS.md is kept** — this repo has one and it is load-bearing.

Deleted:

- `skills/using-skills/references/codex-tools.md`
- `skills/using-skills/references/gemini-tools.md`

(The now-empty `references/` directory goes with them. No remaining file in the repo links to
either reference.)

Deliberately left untouched: the `dot` digraph, the Red Flags rationalization table, the
Skill Priority section, and the Skill Types section.

## Rationale

`using-skills` is the single largest always-loaded item in the plugin. Measured on this branch
with `.claude/scripts/check-context-budget.sh` at `claude-opus-5`, the hook injection was 2,132
tokens against 1,284 for every listed skill description combined — 1.66x. Every token of it is
paid on every session, before the user has said anything.

This fork is Claude Code only (CLAUDE.md, "What This Project Does NOT Do"). Prose instructing an
agent how to activate skills under Gemini CLI, or how to map tool names for Codex, is dead text
in this plugin: it cannot describe a situation this fork ships into. Deleting instructions for
harnesses that are not supported cannot change Claude Code triggering behavior, which makes this
the safe half of the trim.

The behavior-shaping content is the unsafe half and is out of scope here. Upstream warns those
sections are tuned; cutting them would save more tokens but could depress trigger rate, and this
repo's triggering measurement is the acknowledged-flaky one
(`.claude/scripts/probe-skill-triggering.sh`, advisory by design, see
`docs/adr/006-defer-behavioral-evals.md`). That trim stays blocked until a trustworthy triggering
measurement exists.

The reference files are a **correctness** fix, not a cost one. `docs/customizations.md` already
asserted the harness reference files were dropped from this skill; two of them were still on
disk, so the manifest was false. They are not injected by the hook and are not loaded unless
something reads them, so deleting them saves **zero** per-session context. They go because the
fork does not support those harnesses and the manifest should be true.

## Measured Effect

| Tier | Before | After |
|---|---|---|
| descriptions (per-session) | 1,284 | 1,284 |
| hook injection (per-session) | 2,132 | 1,939 |
| **always-loaded total** | **3,416** | **3,223** |

`.claude/scripts/token-diff.sh`: SKILL.md −193, codex-tools.md −392, gemini-tools.md −609,
net −1,194 tokens on disk — of which only the 193 recur per session.

`BUDGET` in `check-context-budget.sh` drops 4100 → 3900. That preserves the original ~20%
headroom rule over the new 3,223 surface, leaving 677 tokens spare. Three in-flight branches each
add a skill, and their listed descriptions measure 106 (`implementer-contract`), 63
(`scripted-browser-verification`) and 79 (`ux-audit`) — 248 tokens, landing the surface at ~3,471
with ~429 to spare. At this repo's ~76-token average listed description that remaining headroom is
about five more skills, not a dozen. The budget tracks the measured surface; it is not shaved to
the bone and not left slack enough to hide a regression.
