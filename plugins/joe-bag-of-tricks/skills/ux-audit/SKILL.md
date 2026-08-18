---
name: ux-audit
description: Use when a UI feature batch is finished but a human has not seen it yet - catches truncated text, crowding, cryptic labels, weak hierarchy, and broken empty states before they are reported
---

# UX Audit

## Overview

**Core principle:** Report the UI's problems before your human partner has to. A batch of frontend
work is not done when it functions — it is done when someone has looked at it at every viewport it
will be used at, and written down what is wrong.

Roughly half of user-reported UI complaints are mechanically detectable: text clipped by a column,
a panel that ate the table, an abbreviation nobody outside the codebase can read. This skill runs
that pass first.

## When to Use

- A UI feature batch is complete and about to be handed over
- Before asking for design feedback — clear the mechanical findings first
- Not for: a backend change with no rendered surface, or a UI you have already audited unchanged

## Mechanical vs. Judgment

Two different things happen in one run. Do not confuse them.

| # | Check | Kind | How |
|---|-------|------|-----|
| 1 | Truncation sweep | **Mechanical** | `scrollWidth > clientWidth` on every clipping text element |
| 2 | Viewport matrix | **Mechanical** | every check re-run at each configured viewport |
| 3 | Label comprehensibility | **Judgment** | script extracts labels; *you* decide if a first-time user reads them |
| 4 | Crowding | **Mechanical** | primary content's share of viewport area vs. a configured floor |
| 5 | Hierarchy / focal point | **Judgment** | *you* read the screenshots |
| 6 | Empty and edge states | **Both** | mechanical sweep re-run against zero-data / long-value / feature-absent routes |

**A script cannot decide whether a label is comprehensible or a layout has a focal point.** For 3
and 5 the script's only job is to capture evidence — a labels file and a screenshot. The finding is
yours. Never report a judgment check as "PASS" because the script exited 0.

## Running It

**REQUIRED BACKGROUND:** scripted-browser-verification. The audit's browser work obeys its rule
without exception — one Node Playwright script, all assertions in code, run via Bash, headless.
Never step through interactive browser tool calls.

You **extend the project's existing `verify.js`**; you do not write an audit script. Copy
[ux-checks.js](ux-checks.js) in beside it once, then add check entries:

```js
const { sweepTruncation, assertPrimaryContentShare, captureLabels } = require('./ux-checks.js');

const tag = (page) => `${page.viewportSize().width}x${page.viewportSize().height}`;

const checks = [
  {
    name: 'ux audit — no truncated text on the dashboard',
    path: '/',
    async run(page) {
      await sweepTruncation(page, {
        reportFile: path.join(config.evidenceDir, `truncation--${tag(page)}.json`),
      });
    },
  },
  {
    name: 'ux audit — primary content keeps most of the viewport',
    path: '/',
    async run(page) {
      await assertPrimaryContentShare(page, {
        selector: config.primaryContent,
        minShare: config.primaryContentMinShare,
      });
    },
  },
  {
    name: 'ux audit — capture labels for comprehensibility review',
    path: '/',
    async run(page) {
      await captureLabels(page, {
        reportFile: path.join(config.evidenceDir, `labels--${tag(page)}.json`),
      });
    },
  },
];
```

Everything project-specific lives in `verify.config.json` — `viewports`, `primaryContent`,
`primaryContentMinShare`, `evidenceDir`, and the routes each check visits. **Never hardcode a
viewport size, selector, ratio, or URL in a check.** If the project has no viewport matrix yet,
agree one with your human partner and write it to the config; a matrix normally spans full screen,
laptop, and a half-width tile, because a half-width tile is where truncation shows up first.

For check 6, point checks at the app's zero-data, feature-absent, and longest-value fixtures. Same
sweeps, different routes.

Then: run once, read the labels file and the screenshots, write the findings.

## Output Contract

A findings list the standard fix loop can consume — one line per finding:

```
[SEVERITY] check — what is wrong — where — evidence path
```

| Severity | Means |
|----------|-------|
| High | Information is lost or unreadable: text clipped, primary content squeezed out, empty state broken |
| Medium | Understandable only to someone who knows the codebase: cryptic label, no focal point |
| Low | Polish; nothing is lost |

Every finding cites evidence — a screenshot path, or an entry in the truncation/labels file. A
finding with no evidence is an opinion; either get the evidence or drop it. Report "no findings"
only after both the mechanical run passed **and** you looked at the screenshots.

## Red Flags - STOP

- Reporting judgment checks as passed because the script exited 0
- Auditing at one viewport because "it looks fine on my screen"
- Hardcoding a viewport, selector, or ratio into a check instead of the config
- Writing a fresh audit script beside the project's `verify.js`
- A finding with no screenshot or evidence file behind it
- Handing the batch over before the audit, planning to audit "if they complain"

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "The tests pass, the UI works" | Functioning and legible are different properties. This checks the second |
| "I'll notice truncation in the screenshot" | You will not, at three viewports, reliably. The sweep does |
| "The abbreviations are obvious" | Obvious to you, after building it. That is exactly the failure mode |
| "Empty states are an edge case" | An empty state is the first thing a new user sees |
| "There's no design spec to audit against" | These six checks need no spec. Run them |
