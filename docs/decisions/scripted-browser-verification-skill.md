# Scripted Browser Verification: a Fork-Original Skill, Not a Section

## Decision

The "browser verification runs as one Playwright script" rule ships as a new fork-original skill,
`plugins/joe-bag-of-tricks/skills/scripted-browser-verification/` (SKILL.md + a reusable `verify.js`
template), rather than as a section appended to `verification-before-completion`. The only change to
`verification-before-completion` is a two-line pointer inside its existing fork-added Visual
Verification section.

The rule: browser verification is ONE Node Playwright script executed via Bash with all assertions
in code — never step-by-step interactive browser tool calls. Output is a compact pass/fail summary
plus screenshot paths, never page dumps. Projects keep a reusable `verify.js` that agents extend
rather than rewrite. Always headless, viewports declared explicitly and sourced from project config.

## Rationale

- `verification-before-completion` is classified **patched** in `docs/customizations.md` — it has a
  live upstream counterpart, and the fork's standing rule (CLAUDE.md, `.claude/rules/git-workflow.md`)
  is to never express a divergent workflow inside an upstream file. A multi-section
  Playwright/tooling procedure is exactly that kind of divergence; adding it would grow the hand-merge
  surface on every future sync for content upstream will never carry.
- The rule needs progressive disclosure to a supporting file (`verify.js`). `writing-skills` puts
  reusable tooling in a skill directory beside its SKILL.md; a patched upstream skill is the wrong
  home for a fork-owned script.
- Separation of concerns matches the two skills' jobs: `verification-before-completion` is the
  *gate* ("evidence before claims"); this skill is the *procedure* for producing that evidence for a
  web UI. The pointer keeps them linked without duplicating either.
- Not folded into `example-skills:webapp-testing`: that skill belongs to a different plugin, and
  `joe-bag-of-tricks` is explicitly non-composable — it may not depend on another plugin being
  installed, and this repo does not edit skills it does not own.
- Motivation: in the 2026-08-13 MISSION-CONTROL session, interactive browser verification was a top
  token cost — roughly 60-100 tool calls per UI fix, because each interactive call returns a full
  page snapshot into context. Scripted runs cut that to about a third while keeping verification
  fully autonomous.
- Cost if wrong: a second verification-adjacent skill is one more description competing for
  triggering, and the rule could be missed by an agent that loads only
  `verification-before-completion`. Mitigated by the pointer in its Visual Verification section.
- The bundled `verify.js` was executed against a live local page on Playwright 1.62.1 (both the
  passing and the failing path) before being committed — no Playwright API in it is unverified.
