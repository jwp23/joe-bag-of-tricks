# Agent Instructions State the Cost, Not the Procedure

## Decision

When a skill or agent body tells a subagent how to work, it names **the cost being avoided** and
leaves the method open. It does not name a procedure.

- ❌ Procedure: "Read each file you will edit once, in full, before you edit it."
- ✅ Cost: "What costs you is reading the same file twice, or in slices — not how many files you
  took in at once. Pulling several files in with one command beats one call per file."

This applies to how-to-work guidance. It does **not** apply to protocol constraints — scope
boundaries, the no-subagents rule, status vocabulary, the report contract. Those name a required
output or a prohibition, are not procedures for the model to perform, and measure as the most
robust part of the contract.

## Rationale

A procedural instruction is executed as a literal step, and it displaces whatever strategy the
model would otherwise have chosen. Measured, not reasoned:

| `implementer-contract` variant | tool calls | subagent tokens | return message |
|---|---|---|---|
| Efficiency guidance, **goal-shaped** | 16, 16 | 43.0k, 42.5k | 10 lines, 9 lines |
| No efficiency guidance (the contract before this) | 19 | 45.9k | 16 lines / 208 words |
| **Protocol-only** — all how-to-work stripped | 20, 20 | 47.1k, 46.9k | 10 lines, 6 lines |
| Efficiency guidance, **procedural** | 24 | 45.6k | 11 lines |

One dispatch of `joe-bag-of-tricks:implementer-complex` per cell, against an identical
discovery-shaped fixture (nine files, tuning constants to centralize, no code in the brief). Every
arm produced correct work: 4 pre-existing tests unchanged and passing, all acceptance criteria
met. The two replicated arms hit the same call count on both runs, so the ordering is not noise.

**Procedural is the worst arm.** The 24-call run differs from the 16-call run by one bullet and
nothing else. The procedural phrasing produced nine separate `Read` calls, one per file; the
goal-shaped phrasing produced a single `cat` loop over all nine. The model's own default —
visible in the two arms with no guidance at all — was already the `cat` loop. The procedure did
not add discipline; it removed a better plan.

**Stripping guidance is the second-worst arm, not the best.** This was the live hypothesis: that
an over-specified contract was crowding the model out, and less prose would run leaner. It does
not. Protocol-only spent its freed budget on self-invented overhead — `git remote -v`,
`git branch --show-current`, two separate greps hunting the same literals, a test run *after* the
commit — and finished with the highest token count of the four arms. Absent guidance, the model
does not do less; it does its own thing, and its own thing is worse than good guidance.

**The return contract is tier- and context-independent.** It held at 6–11 lines in every arm that
carried it, including protocol-only, against 16 lines / 208 words without it. It also held on
`implementer-mechanical` (haiku) across three separate runs. Constraining an output is reliable in
a way that constraining a method is not — which is the same distinction this decision rests on.

## Consequences

- The `Working Efficiently` section in `implementer-contract` ships in goal-shaped form.
- Reviewing a skill or agent edit includes asking of each how-to-work line: is this a step the
  model will perform, or a cost it can route around? A step is a defect.
- A rule that a model ignores every run gets deleted rather than escalated. An absolute
  "no `find`, no `ls`, no `Glob`" was tried in `implementer-mechanical` and dropped after 3/3
  fixture runs violated it — a contract with a dead rule in it teaches that the contract is
  ignorable.
- This is one fixture, one tier, one task shape. It is enough to choose a phrasing, not enough to
  claim a law. `docs/adr/006-defer-behavioral-evals.md` still stands: there is no standing harness
  and this measurement was hand-built for one question.

## Cost if wrong

Goal-shaped phrasing is longer per rule than procedural phrasing, so the contract costs slightly
more to carry. It is loaded on demand into implementer dispatches only, never into the
always-loaded surface the context budget gates, so the downside is bounded at a few hundred
tokens per dispatch against a measured ~3–4k token saving per dispatch.
