---
name: scripted-browser-verification
description: Use when verifying a web UI in a browser - proving a page renders, a flow works, or capturing screenshots after a frontend change
---

# Scripted Browser Verification

## Overview

**Core principle:** One script, run once, compact output. A browser verification is a program you
run, not a conversation you have with a browser.

Interactive browser tool calls return a full page snapshot into context on *every* call. A UI fix
verified that way costs 60-100 such calls. The same verification as a single scripted run costs
about a third of the tokens and stays fully autonomous — nothing about it needs a human.

## The Rule

```
Browser verification runs as ONE Node Playwright script, executed via Bash,
with every assertion in code.

NEVER verify by stepping through interactive browser tool calls.
```

Applies to `mcp__*browser_*` tools and any other click/type/snapshot-per-call browser interface.

## Output Contract

The script prints, and only prints:

- one `PASS`/`FAIL` line per check, with the failure reason on failure
- an `N/M passed` summary
- screenshot **paths**

No page dumps. No DOM, no accessibility tree, no full HTML in stdout. Read a screenshot with the
Read tool only when a check fails and the reason is not enough to diagnose it.

Exit code is the verdict: 0 = all passed.

## Quick Reference

| Requirement | Why |
|-------------|-----|
| One script per run, all assertions in code | Assertions in code cost tokens once, not once per step |
| Project keeps a reusable `verify.js` | Extending an existing harness beats rewriting one each time |
| Always headless | No display dependency; runs the same in any session |
| Viewports declared explicitly, from project config | Layout results are meaningless without a stated viewport |
| Screenshots always written, pass or fail | The failing case is exactly when you need the image |

## Using It

1. Find the project's harness (conventionally `scripts/verify.js` with a `verify.config.json`
   holding `baseUrl`, `screenshotDir`, and `viewports`). If none exists, copy
   [verify.js](verify.js) in and write the config — once.
2. **Extend `checks`** with an entry for the behavior you changed. Do not rewrite the harness, and
   do not start a second script beside it.
3. Run it in one Bash call: `node scripts/verify.js [name-substring]`.
4. Report the summary and the screenshot paths as your evidence.

Never invent viewport sizes, URLs, or ports in the script — they come from the project config.

## Red Flags - STOP

- About to call a browser tool to navigate, click, type, or snapshot "just to check"
- "I'll drive it interactively first, then script it once it works"
- Writing a throwaway `check-this-fix.js` next to the existing harness
- `headless: false`, or launching with no viewport set
- Printing `page.content()`, an accessibility snapshot, or element HTML to stdout

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "It's a one-line CSS fix, one click proves it" | One click is one full page snapshot in context. Add a check instead |
| "Interactive is faster for exploring" | Exploring is not verifying. The verification is still a script |
| "The harness doesn't cover this page" | That is what extending `checks` is for |
| "I need to see the page to know what to assert" | Read the source, or screenshot once from the script and Read the file |
| "Headed mode is easier to debug" | Nobody is watching. Screenshots are the debug channel |

**REQUIRED BACKGROUND:** verification-before-completion — this skill is how its Visual Verification
step gets carried out for web UIs.
