---
name: authoring-beads
description: Use when asked to create or file a bead outside a planning session — "make a bead for X", "file this GitHub issue as a bead", "track this in bd" — before running bd create.
---

# Authoring Beads

## Overview

A bead a crunch agent runs is a contract: the agent gets the bead fields plus the codebase,
nothing else. This skill authors ONE well-formed ad-hoc bead — a GitHub issue, a stray idea, a
discovered bug — outside the brainstorming → writing-plans pipeline.

**Ask first. Draft second. Create third.** Drafting from a one-liner anchors your partner to
your guesses and fabrications; elicit the gaps before you draft.

## When to use vs route elsewhere

| Situation | Path |
|---|---|
| "Make a bead for X" and X isn't fully specified | this skill |
| Single task / bug / small feature | this skill |
| Needs design exploration ("let's build X") | brainstorming skill |
| Epic-sized: spans components, multi-PR | brainstorming → writing-plans — never outline children here |
| Follow-up discovered mid-task, clear scope | tight `bd create` directly, `--deps discovered-from:<id>` |

## Gap questions — one batch, only what you don't have

Skip anything the user already gave or that you verified in the codebase.
- **Outcome:** what's true after this ships that isn't now? What's out of scope?
- **Location:** which files/modules? How does an agent verify — exact test command?
- **Bugs:** repro steps, symptom, frequency. **No repro → triage stub** (below).
- **Risk:** what must this NOT change? Blocks or blocked by anything?

Unknowable now → open question in `--notes`, never a guess in acceptance.

## Nothing invented — everything grounded

Every specific in the bead comes from the user, the linked issue, or the codebase **you
actually read**. The cost of a plausible-sounding guess is a crunch agent burning a run chasing
machinery that doesn't exist — a baseline test fabricated an entire notification subsystem,
"likely races" included, for an app with two REST routes.
- Before naming files, paths, functions, or a subsystem: read them. If the code the issue
  implies doesn't exist, that IS the finding — put it in `--notes` as an open question.
- Source links: record the real URL, or write "source URL not provided". Never construct one.
- Priority: ask, or default P2. Don't invent urgency from the reporter's tone.

## Autonomy default

Every bead defaults to autonomous execution — a crunch agent picks it up and finishes without a
human. Label the exceptions via `bd label add <id> human-decision` (needs human authority: scope
approval, library/vendor/threshold choice) or `human-run` (needs human hands or accounts: UI
click-through, portal approval, hardware).

Before applying either label, probe your partner ONCE: "is there tooling — an allow rule, a
non-interactive flag, an MCP server — that would let an agent do this? If so I'd file a prereq
tooling bead and block on it." Partner reaffirms → label and move on; don't re-litigate.
Any command in `--notes` must run unattended — embed the non-interactive form.

## Fields — plugin conventions

| Field | Holds | Smell test |
|---|---|---|
| `--description` | why this exists, what changes, source link | could a fresh agent read this and know the goal? |
| `--acceptance` | verifiable outcomes | still true if the implementation were rewritten? |
| `--design` | approach, trade-offs — allowed to change | "use X library" lives HERE, not in acceptance |
| `--notes` | where to look, how to verify (exact commands), out of scope, open questions | the agent's cheat sheet |

- Hierarchy: `--parent <id>`. Ordering: `bd dep <blocker-id> --blocks <blocked-id>`.
- N siblings under one parent, once the parent ID is back: one Bash call chaining every
  `bd create --parent <id>` for them. Each serial call is a full model turn re-sending the whole
  session — the cost compounds with sibling count, not with how many distinct commands they are.
- Never write "invoke skill X" or "run /command" in a bead — crunch agents have no Skill tool.
  Name the procedure's file instead.
- Type `task|bug|feature`; priority `0..4`, never "high/medium/low".

## Vague bug → triage stub

A bug with no reproduction is not actionable. File it with acceptance
"TBD — needs triage" and do NOT hand it to a crunch agent as runnable. Filing it as actionable
anyway is the failure this skill exists to stop.

## Search before filing

A bead filed without checking is a coin flip on duplicating one that already covers the same
symptom or topic — the partner then owns two half-histories of the same problem with no link
between them, and whichever a crunch agent picks up first is luck, not judgment. Before
`bd create`, spend one `bd search`/`bd list` against the symptom or topic. A covering bead
already open? Link the two (`bd link <id> <id> --type related`) or extend the existing bead's
notes/description — don't file a new sibling for ground it already covers.

## Confirm before `bd create`

Show the assembled bead in plain text (title, type/priority, labels, description, acceptance,
design, notes) and get a thumbs-up. Never `bd create` on the same turn the request arrived.

**Time pressure is the red flag, not the bypass.** "I'm heading into a meeting — just get it
filed" does not waive the gaps; the meeting outlasts the bad autonomous run the guessed bead
causes. The only bypass is your partner explicitly saying "just file it" — and even then, state
every assumption and TBD in `--notes`, and keep a no-repro bug a triage stub.

## Rationalizations

| Excuse | Reality |
|---|---|
| "Partner is busy — file now, refine later" | The crunch runs before "later". Ask in one batch or file a triage stub. |
| "The codebase almost certainly has X" | Read it. Baseline agents fabricate subsystems under exactly this thought. |
| "A rough URL is better than none" | A wrong link misdirects; "not provided" is honest and fixable. |
| "It's obviously P1" | Urgency comes from the partner, not the report's tone. |
| "The agent can figure out repro" | Intermittent + no repro = a burned run. Triage stub. |
| "Close enough title — search would just waste a call" | The call is one `bd search`; the miss is a duplicate with no link, split across two histories. |

## Red flags — STOP

- `bd create` on the same turn the bead was first mentioned
- `bd create` with no prior `bd search`/`bd list` for the symptom or topic
- A file, function, subsystem, or URL in the draft you didn't read or receive
- Acceptance words that came from neither the partner nor the codebase
- A `bug` with no repro heading into a crunch as actionable
- `human-*` label without the one-time tooling probe
