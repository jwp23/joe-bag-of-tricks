# Carry upstream's Claude Code nested-orchestrator note as a using-skills reference

## Decision

Vendor upstream v6.4.1's `skills/using-superpowers/references/claude-code-tools.md` as
`skills/using-skills/references/claude-code-tools.md` (namespace rebranded; "ledger" → "bd state")
and add a one-line "Claude Code Tool Notes" pointer to `using-skills`. It describes the one
opt-in way Claude Code runs a plan cheaper than the skills' default shape: when the human partner
asks for it, dispatch ONE orchestrator subagent on a mid-tier model to run
subagent-driven-development end to end one layer down, relaying its "Rulings I made" list verbatim.

## Rationale

`docs/customizations.md` had recorded that the `references/` directory under `using-skills` was
gone and that harness reference files are never vendored. That rule was about *other* harnesses;
this file is Claude Code's own and is the harness this plugin targets. The pointer line costs
per-session budget because `using-skills` is injected at SessionStart (Joe's call, 2026-10-10:
keep it even at that cost); the reference file itself loads only when followed.
