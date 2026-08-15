# Defer Behavioral Token-Cost Measurement

## Decision

**Do not build an A/B "does this skill make the session cheaper" harness.** Nothing is added to
`.claude/scripts/`, nothing is added to any gate list in `.claude/rules/validating-changes.md`,
and upstream's `tests/claude-code/analyze-token-usage.py` is **not** vendored.

This closes `joe-bag-of-tricks-4a6.4` as *deferred, not rejected* — the same posture
`docs/adr/006-defer-behavioral-evals.md` takes toward Quorum. The flip conditions are at the
bottom, and the telemetry facts are recorded here so a revisit does not re-derive them.

If it is ever built, it is **advisory output only** — printed for a human to read, always exit 0,
never referenced by a "Before Every Commit" list.

## Rationale

### The epic already shipped the half that can be a gate

`joe-bag-of-tricks-4a6` split context cost into what is paid every session and what is paid on
demand. The deterministic half landed: `.claude/scripts/check-context-budget.sh` counts skill
descriptions plus the SessionStart injection through the Anthropic `count_tokens` endpoint and
hard-fails over `BUDGET`, and `.claude/scripts/token-diff.sh` reports the per-edit delta while
authoring. No inference, no variance, so it is a real gate.

Behavioral token cost is the other half by construction: it asks what a *model* did with the
skill, which means running sessions and comparing distributions. That is an eval. ADR-006 already
weighed evals for this fork and deferred them; nothing about relabelling the output "tokens"
instead of "did it trigger" changes that calculus.

### The cache split is the part actually worth measuring

Prompt caching is a **prefix match**. Any edit to an always-loaded surface — a skill description,
the `using-skills` body the SessionStart hook injects — invalidates the cached prefix from the
edit point onward, and the next session pays `cache_creation_input_tokens` instead of
`cache_read_input_tokens` for everything after it.

That gives one signal that is diagnostic rather than statistical: **`cache_read_input_tokens`
sitting near zero across repeated, unedited runs means something upstream in the prompt is
changing every session.** A silent invalidator — a timestamp, a hook injecting varying text, a
reordered list — costs full input price on every turn of every session forever, and nothing else
in this repo would notice.

That is a *one-shot inspection*, not an A/B. It needs two runs and a look at one number. It does
not need a harness, N-run averaging, or a with/without corpus. If the question ever comes up, the
answer is to read the `usage` block of the `result` event, not to build tooling.

### Telemetry — verified, with a correction

Verified 2026-08-14 by capturing a real terminal `result` event:

```
claude --model haiku --output-format stream-json --verbose --allowedTools '' \
       -p "Reply with exactly: DONE" | jq -c 'select(.type=="result")'
```

The bead's field list is right about *what exists* and wrong about *where*. Correcting it here so
nobody writes a `jq` path that silently yields `null`:

- **Top level of the `result` event:** `duration_ms`, `duration_api_ms`, `num_turns`,
  `total_cost_usd`, `subtype`, `is_error`, `stop_reason`, `session_id`.
- **Nested under `usage`:** `input_tokens`, `output_tokens`, `cache_creation_input_tokens`,
  `cache_read_input_tokens`, plus `cache_creation.{ephemeral_5m,ephemeral_1h}_input_tokens` and a
  per-message `iterations` array.
- **Nested under `modelUsage`, keyed by model id:** the same counts in camelCase plus `costUSD`
  and `contextWindow` — which is where a per-model breakdown would come from.

`.claude/scripts/verify-skills-load.sh` reads only `.total_cost_usd` (top level, hence correct).
Everything above is already on the stream it parses, so the data is free; it is the
*interpretation* that is expensive.

### A/B flakiness rules out gating — same evidence as the triggering probe

Comparing with-skill against without-skill needs N runs per arm, because a single run's token
count moves with turn count, tool choice, and cache state. ADR-006 measured what that variance
looks like in this repo: identical prompts gave `test-driven-development` and `writing-plans`
**1/2** hit rates across two runs. Token totals inherit that variance and add their own — a run
that takes one extra turn shifts the total more than most skill edits ever will.

Under this project's pristine-output rule a gate that flips on identical input is worse than no
gate: it trains everyone to ignore a red result. And the runs are billed. The load gate is
already $2.75 for 18 single-turn sessions; an A/B needs multi-turn sessions times N times two
arms, for a number whose confidence interval would swamp the effect being measured.

### The prior art is real and MIT, and still not worth vendoring

Confirmed via the GitHub API (this fork has no upstream remote, per
`docs/adr/002-no-remote-upstream-sync.md`): `tests/claude-code/analyze-token-usage.py` exists at
`obra/superpowers` `v6.3.0`, 6,733 bytes, and `obra/superpowers` reports `spdx_id: MIT`. So unlike
`prime-radiant-inc/superpowers-evals` it *could* be vendored.

Reading it changes the answer. It:

- parses a **Claude Code session transcript `.jsonl`** (`~/.claude/projects/...`), not
  `stream-json` output — a different input than anything this repo already produces;
- attributes subagent usage by matching `type == "user"` records carrying both `toolUseResult.agentId`
  and `toolUseResult.usage`, which is the genuinely clever part and the only thing here this repo
  cannot already get from a `result` event;
- hardcodes `$3/$15` per M tokens, and bills `cache_read` at the **full base input rate** — cache
  reads are the cheapest input tier, so its cost column overstates a cache-warm session badly.
  The API already returns `total_cost_usd` correctly, so that whole code path would be deleted on
  vendoring anyway;
- swallows every parse error with a bare `except Exception: pass`, which SonarCloud would flag on
  a new file — and the quality gate is this repo's only blocking PR check.

Vendoring it under `docs/licensing.md` would require: preserving MIT attribution and not stripping
authorship, adding the top-level `NOTICE` this repo still does not have, and a
`docs/customizations.md` row moving it out of the blanket `tests/*` drop. That is real overhead for
a script whose useful 20 lines answer a question nobody has asked yet.

**Conclusion:** if the subagent-attribution question ever becomes live, vendor it *then*, and
carry the cost math over the side. `docs/customizations.md` keeps it dropped for now, with a
pointer here.

## Trade-offs

**Chosen: defer, record the telemetry, build nothing**

- Costs nothing and adds no billed step to any workflow.
- The one genuinely diagnostic signal (cache-read collapse) is written down as a two-run
  inspection, so it is available without tooling.
- Corrects a field-location error in the bead before it becomes a broken `jq` path in a script.
- Cost: no answer to "did that skill rewrite make sessions cheaper". Accepted — the surface that
  is paid unconditionally is already gated, and a skill body only costs anything when it loads.

**Rejected: build the A/B harness now**

- The only version that answers the question honestly needs N runs per arm and multi-turn
  sessions, which is per-run cost with a confidence interval wider than the effect.
- Would produce a number that looks authoritative and is not — worse than no number.

**Rejected: vendor `analyze-token-usage.py` now**

- Licensing permits it; fit does not. Wrong input format, stale and incorrect cost math, and a
  SonarCloud-hostile error handler, for one idea (subagent attribution) that is not currently
  needed.

**Rejected: fold this into `check-context-budget.sh`**

- That script is a hard gate precisely because it is deterministic. Attaching an inference-driven,
  variance-carrying measurement to it would contaminate the one clean gate the epic produced.

## Revisit Trigger

Build it when one of these is true — not before:

- **A cache-invalidation suspicion.** Sessions in this repo feel expensive relative to their
  length, or `cache_read_input_tokens` reads near zero on repeated unedited runs. Do the two-run
  inspection first; only build tooling if the inspection cannot localize the invalidator.
- **A subagent-fanout cost question.** This repo dispatches agents from SDD, `branch-shepherd`,
  and the reviewer ladder. If per-agent cost attribution becomes a live question, that is exactly
  what `analyze-token-usage.py` does, it is MIT, and vendoring it becomes worth the NOTICE +
  manifest overhead.
- **A trustworthy behavioral measurement exists**, i.e. ADR-006's own revisit trigger fires. If
  something can already run N sessions reliably, the token deltas ride along on the `result`
  events it is parsing anyway, and the marginal cost of this drops to near zero.
- **A skill body grows large enough to matter on load** — a single SKILL.md whose body dwarfs the
  rest, where the on-demand assumption stops holding.

Absent those, `.claude/scripts/check-context-budget.sh` plus `token-diff.sh` is the whole of this
repo's token measurement, and that is the intended end state.
