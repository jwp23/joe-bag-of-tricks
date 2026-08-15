# Validation Rules

No TDD and no behavioral evals for this repo — deferred by
`docs/adr/006-defer-behavioral-evals.md`. Validation = prove the plugin still loads and every
skill still resolves, before committing.

## Before Every Commit
- `claude plugin validate plugins/joe-bag-of-tricks` — plugin manifest + skill frontmatter. Hard
  fail. The path argument is REQUIRED (the bare command exits with `missing required argument
  'path'`), and it MUST be the **plugin root** — the dir holding `.claude-plugin/plugin.json`.
  `claude plugin validate .` resolves to the repo-root *marketplace* manifest instead and passes
  without ever reading a skill, so it will NOT catch broken skill frontmatter.
- `.claude/scripts/verify-skills-load.sh` — the scripted "load and observe". One non-interactive
  session per skill; asserts a `Skill` tool_use for the namespaced name, a successful terminal
  result, and that the SessionStart hook injected `using-skills`. Hard fail (non-zero exit, with
  the stream tail for each failure). Runs `replaced` skills first, then `patched`, then the rest,
  per the `State` column of `docs/customizations.md`. Use `--only <name>` while iterating on one
  skill and `--tier diverged` for the 12 fork-owned ones; the bare command covers all 19.
  **One model call per skill — it is billed**, which is why it is an explicitly-run gate and not
  a git pre-commit hook.
  `--plugin-dir <path>` points the same gate at any plugin root — use it to verify
  `plugins/joe-magic-bootstrap` rather than replicating the probe by hand. The namespace asserted
  in the `Skill` tool_use is read from that plugin's `.claude-plugin/plugin.json` `name`.
  `docs/customizations.md` classifies `plugins/joe-bag-of-tricks` only, so against another plugin
  the ordering degrades to alphabetical (the script says so) and `--tier diverged` is refused
  instead of silently selecting nothing. The `using-skills` SessionStart assertion likewise applies
  only to the plugin that ships that skill.
  The plugin-root rule applies to the script's flag and to anything you run by hand: the path must
  hold `.claude-plugin/plugin.json`. `--plugin-dir .` is the repo-root marketplace and loads no
  skills — the script now rejects it outright.
  This proves a skill **loads when named**. It does NOT prove a skill **triggers** from a natural
  prompt — see `docs/adr/006-defer-behavioral-evals.md`. It is not an eval; don't call it one.
- `.claude/scripts/check-context-budget.sh` — context-budget gate. Hard fail. Counts, via the
  Anthropic `count_tokens` endpoint at `claude-opus-5`, the surface loaded into **every**
  session: skill descriptions in the available-skills list, plus what the SessionStart hook
  injects. Fails when the two together exceed the `BUDGET` committed in the script — read the
  current value and the measured surface from the script and its output, never from here, so
  there is one source of truth to drift from. SKILL.md bodies are reported but not gated — they
  load on demand. Not billed as inference, so unlike `verify-skills-load.sh` this one is cheap to run
  every time. Raising `BUDGET` is a deliberate decision, not a way to make the gate pass.
  NEVER estimate these counts with tiktoken or chars/4 — OpenAI tokenizers undercount Claude
  markdown. Needs the `anthropic` Python SDK and an `ant auth login` profile; a set (even empty)
  `ANTHROPIC_API_KEY` shadows that profile — check with `ant auth status`.
- `betterleaks git --pre-commit --staged --redact` — secret scan. Hard fail.

## Before a Sync, and Before Any PR That Touches a Skill
`.claude/scripts/check-vendored-drift.sh` — proves every skill classified `vendored` is still
byte-identical to `obra/superpowers` at the **Last synced** ref in `docs/customizations.md`. A
`vendored` file is taken to upstream head wholesale by the next sync, so a fork edit that lands
while the row still says `vendored` gets silently wiped — that already happened once
(`dispatching-parallel-agents/SKILL.md`, caught by hand). Hard fail: it names each drifted file,
shows the drift size (`--diff` for the full unified diff), and exits non-zero. It does **not**
judge whether the drift was intentional — you decide reclassify-to-`patched` vs. revert.

The file list is derived from the manifest — the `| skills/<name> |` rows plus its catch-all
("skills not listed above are vendored") — so a new vendored skill needs no script edit. Use
`--list` to see the classification it derived, `--only <skill>`, or `--ref <tag>` to measure
against a different upstream ref. **Scope limit:** skill *directories*. Individually-vendored
FILES inside a `patched`/`replaced` skill (named only in the manifest's narrative "Vendored
skills" prose, negations and all) are not machine-checkable and remain a hand check.

Cost: no model calls — one GitHub API call for the upstream tree, plus one per drifted file to
render the diff. It is still **not** a git pre-commit hook: it needs the network and an
authenticated `gh`, which a hook must not depend on. Sync time and pre-PR are the natural moments.

## While Authoring a Skill
`.claude/scripts/token-diff.sh [PATH...]` — prints the `claude-opus-5` token delta for each
changed file between HEAD and the working tree (no arguments = everything changed vs HEAD;
`--rev` compares against another ref). `count_tokens` is stateless, so this counts both versions
and subtracts. Advisory, not a gate: it answers "did that edit actually shrink the skill".
It shares its counting core, `.claude/scripts/count-tokens.py`, with the budget gate.

## After an Upstream Sync (advisory, not a gate)
`.claude/scripts/probe-skill-triggering.sh` — sends natural prompts in a throwaway fixture repo
and reports which skill fired. **Always exits 0 by design.** Measured at `--repeat 5` on identical
prompts: `writing-plans` 3/5, `test-driven-development` 1/5 — so it is a signal to go read a
description, never a pass/fail. Run it where description drift is the real risk: after a sync, and
scope it to what actually drifted, which is free to compute:

```
.claude/scripts/probe-skill-triggering.sh --changed-since <last-release-tag> --repeat 5
```

Probe calls are billed (~$0.14–0.18 each). The probe runs `--allowedTools Skill`; that choice and
its cost/realism trade-off are recorded in `../../docs/decisions/triggering-probe-tool-allowlist.md`.

## On Demand: Description Triggering (NOT a gate)
`.claude/scripts/optimize-skill-description.sh <skill>` drives Anthropic's installed
`skill-creator` eval loop — train/test split, three runs per query, description rewritten from
train failures, winner picked by held-out test score. **Nothing blocks on it**; it is a deep tool
for when a skill loads but fires on the wrong prompts. ~$6 and ~3 minutes for 18 queries x 3 runs
x 3 iterations, and spend is not locally measurable. Apply a new description ONLY if it beats the
current one on the held-out test score. Full procedure, eval-set conventions, model choice, and
the Claude-Code compatibility shim: `docs/skill-description-optimization.md`.

## When Editing or Creating a Skill
Follow the `/joe-bag-of-tricks:writing-skills` skill — it carries the skill-testing method.

## Verification Discipline
YOU MUST NEVER claim a change works until you have loaded it and observed it — no "should work."
For "is it actually fixed" confirmation, invoke `/joe-bag-of-tricks:verification-before-completion`.

## Inherited Suites
Upstream `tests/` and `.pre-commit-config.yaml` are kept-or-stripped per
`docs/customizations.md`. If retained, run them; otherwise the floor above stands.
