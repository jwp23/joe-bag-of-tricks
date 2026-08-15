# UX Audit: a Separate Skill That Extends the Verification Harness

## Decision

The heuristic UI review pass ships as a new fork-original skill,
`plugins/joe-bag-of-tricks/skills/ux-audit/` (SKILL.md + `ux-checks.js`), rather than as a section
of `scripted-browser-verification` or a second verification harness.

`ux-checks.js` is a **module of probes**, not a runner: three functions
(`sweepTruncation`, `assertPrimaryContentShare`, `captureLabels`) that a project calls from the
`checks` array of the `verify.js` it already has from `scripted-browser-verification`. There is no
second script, no forked copy of `verify.js`, and no browser entry point of its own — the skill
states `scripted-browser-verification` as REQUIRED BACKGROUND and inherits its rule, output
contract, and viewport handling wholesale.

The six-point checklist is split explicitly by what a script can decide:

- **Mechanical** (assertions in code): truncation sweep (`scrollWidth > clientWidth`), viewport
  matrix, crowding (primary content's share of viewport area).
- **Judgment** (agent reads captured evidence): label comprehensibility, visual hierarchy.
- **Both**: empty and edge states — the mechanical sweeps re-run against zero-data, feature-absent,
  and longest-value routes.

Every project-specific value — viewports, primary-content selector, crowding floor, evidence
directory, routes — comes from `verify.config.json`. Nothing is baked into the skill.

## Rationale

- Motivation: in the 2026-08-13 MISSION-CONTROL session, roughly 4 of 8 user-reported UI issues were
  mechanically pre-detectable — truncated columns, a crowded rollup, unreadable legend
  abbreviations, cryptic model labels. Those four cost a human review round each. A sweep before
  handover is strictly cheaper than a report after it.
- Not a section of `scripted-browser-verification`: that skill is the *rule* for how any browser
  verification runs. This one is a *checklist* for a specific moment (a finished UI batch, before a
  human sees it) with different triggering conditions. Folding them would bloat a rule that must
  stay short enough to be obeyed, and would fire the audit's triggers on every browser check.
- Probes, not a runner: a second harness would duplicate viewport iteration, screenshotting, and the
  output contract, and would immediately drift from `verify.js`. Extending `checks` is exactly the
  extension point that skill already mandates, so the audit costs one `require` and some entries.
- Mechanical/judgment split is stated in the skill rather than left implicit: the failure mode is an
  agent reporting "PASS, no UX findings" because a script exited 0, when the script never had an
  opinion about whether `TPS` is a readable label. The skill's Red Flags list that specific
  rationalization.
- Truncation is defined as *clipped*, not merely overflowing: the sweep only considers elements that
  actually clip (`overflow-x` hidden/clip/auto/scroll, or `text-overflow: ellipsis`) and skips
  inline elements, whose `clientWidth` is 0. Checking `scrollWidth > clientWidth` over every element
  regardless would report mostly noise, and a rule that cries wolf gets switched off.
- Cost if wrong: another verification-adjacent description competing for triggering, and a probe
  module that must stay compatible with `verify.js`'s `check.run(page)` signature. Accepted — the
  functions take `page` plus an options object and nothing else, so they survive any harness that
  hands them a Playwright page.
- Not built on `example-skills:webapp-testing`: that is a different plugin, and `joe-bag-of-tricks`
  is explicitly non-composable.
- `ux-checks.js` was executed against a throwaway static page on Playwright 1.62.1 before being
  committed — both the failing path (2 clipped cells and a 2%-of-viewport table, correctly flagged
  at two viewports) and the passing path (the same page fixed, 6/6, with the deliberately
  non-truncated elements not flagged). No Playwright API or DOM property in it is unverified.
