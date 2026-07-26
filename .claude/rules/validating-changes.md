# Validation Rules

No TDD and no automated evals for this repo yet. Validation = prove the plugin still loads and
the changed component triggers, before committing.

## Before Every Commit
- `claude plugin validate plugins/joe-bag-of-tricks` — plugin manifest + skill frontmatter. Hard
  fail. The path argument is REQUIRED (the bare command exits with `missing required argument
  'path'`), and it MUST be the **plugin root** — the dir holding `.claude-plugin/plugin.json`.
  `claude plugin validate .` resolves to the repo-root *marketplace* manifest instead and passes
  without ever reading a skill, so it will NOT catch broken skill frontmatter.
- `claude --plugin-dir plugins/joe-bag-of-tricks` — load the plugin locally, then confirm the
  changed skill/agent loads and triggers as intended. Same plugin-root rule: `--plugin-dir .`
  silently loads no skills. Non-interactive recipe (drive it from a script/agent, don't eyeball a
  TUI), run from the repo root —
  `claude --plugin-dir plugins/joe-bag-of-tricks -p "Use the Skill tool to load <name>, then
  reply with a line only that skill's content contains" --allowedTools Skill` — and assert the
  reply. This is the repeatable "load and observe" for a changed skill.
- `betterleaks git --pre-commit --staged --redact` — secret scan. Hard fail.

## When Editing or Creating a Skill
Follow the `/joe-bag-of-tricks:writing-skills` skill — it carries the skill-testing method.

## Verification Discipline
YOU MUST NEVER claim a change works until you have loaded it and observed it — no "should work."
For "is it actually fixed" confirmation, invoke `/joe-bag-of-tricks:verification-before-completion`.

## Inherited Suites
Upstream `tests/` and `.pre-commit-config.yaml` are kept-or-stripped per
`docs/customizations.md`. If retained, run them; otherwise the floor above stands.
