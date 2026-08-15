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
  skill and `--tier diverged` for the 12 fork-owned ones; the bare command covers all 18.
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
- `betterleaks git --pre-commit --staged --redact` — secret scan. Hard fail.

## After an Upstream Sync (advisory, not a gate)
`.claude/scripts/probe-skill-triggering.sh` — sends natural prompts in a throwaway fixture repo
and reports which skill fired. **Always exits 0 by design.** Measured 1/2 hit rates on identical
prompts for some skills, so it is a signal to go read a description, never a pass/fail. Run it
where description drift is the real risk: after a sync.

## When Editing or Creating a Skill
Follow the `/joe-bag-of-tricks:writing-skills` skill — it carries the skill-testing method.

## Verification Discipline
YOU MUST NEVER claim a change works until you have loaded it and observed it — no "should work."
For "is it actually fixed" confirmation, invoke `/joe-bag-of-tricks:verification-before-completion`.

## Inherited Suites
Upstream `tests/` and `.pre-commit-config.yaml` are kept-or-stripped per
`docs/customizations.md`. If retained, run them; otherwise the floor above stands.
