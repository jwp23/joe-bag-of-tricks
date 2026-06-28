# Validation Rules

No TDD and no automated evals for this repo yet. Validation = prove the plugin still loads and
the changed component triggers, before committing.

## Before Every Commit
- `claude plugin validate` — manifest/structure. Hard fail.
- `claude --plugin-dir .` — load the plugin locally, then confirm the changed skill/agent
  loads and triggers as intended.
- `betterleaks git --pre-commit --staged --redact` — secret scan. Hard fail.

## When Editing or Creating a Skill
Follow the `/joe-bag-of-tricks:writing-skills` skill — it carries the skill-testing method.

## Verification Discipline
YOU MUST NEVER claim a change works until you have loaded it and observed it — no "should work."
For "is it actually fixed" confirmation, invoke `/joe-bag-of-tricks:verification-before-completion`.

## Inherited Suites
Upstream `tests/` and `.pre-commit-config.yaml` are kept-or-stripped per
`@docs/customizations.md`. If retained, run them; otherwise the floor above stands.
