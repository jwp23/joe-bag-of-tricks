# Triggering Probe: Keep the Tool Allowlist at `Skill`

## Decision

`.claude/scripts/probe-skill-triggering.sh` keeps `--allowedTools Skill`. The probe agent can load
a skill and nothing else — no file reads, no edits, no bash, no subagent dispatch.

Rejected: running the probe with full tools, running it with a read-only subset
(`Skill Read Grep Glob`), and capping realism-driven runs with prompt-level turn limits.

## Rationale

The probe exists to detect **drift** — did this skill still fire after the description changed?
That is a comparison between two runs of the same prompt against two versions of a description,
and both sides run under the same allowlist. The relative signal, which is the whole product, is
unaffected by how narrow the allowlist is. What a narrow allowlist gives up is *absolute* realism:
the tool roster is in context when the model makes its triggering decision, so a session with full
tools genuinely can decide differently than this one does. The probe therefore does not claim to
predict what a real session does; it claims a description that stopped firing here probably
stopped firing there too. That is the claim a $2 post-sync check can honestly support.

Widening is not cheap and, more importantly, is not bounded. Measured: with a permissive prompt
and tools, `requesting-code-review` did what the skill says to do — dispatched a reviewer subagent,
ran ten turns, and hit the 180s timeout having spent **$0.86** on a single probe. The constrained
probe is **$0.14–0.18**. That is roughly a 5x floor with no ceiling, because `claude` has **no
`--max-turns` flag** (verified against `claude --help`; only `--allowedTools` /
`--disallowedTools` exist). The only spend brake available is `--timeout`, which caps wall-clock,
not tokens, and a timed-out probe still bills for everything it did first. Full tools would make
the sweep's cost a function of how agentic the triggered skill happens to be — precisely the
skills this fork cares most about, since the workflow skills all dispatch subagents.

The read-only middle ground is the tempting one and it was rejected on evidence, not principle:
the fixture repo the probe builds is two files (`package.json`, `src/utils.js`). There is nothing
in it to read. Granting `Read`/`Grep`/`Glob` buys extra turns and extra spend in exchange for the
agent confirming what the prompt already told it. If the fixture ever grows into something a
realistic prompt would have to explore before acting, this is the first thing to revisit.

Prompt-level turn caps were rejected outright for this script, even though
`verify-skills-load.sh` uses one ("do NOT follow the skill's instructions") to keep its own cost
at $0.14. That works there because the load gate names the skill explicitly and only asks whether
it resolves. Here, instructing the agent to hold back is instructing it about the very decision
being measured — it contaminates the result. The prompt must stay a plain user request, so the cap
has to live outside the prompt, which means the allowlist.

Realism is bought at tier 2 instead. `example-skills:skill-creator`'s description-optimization
loop is the deep, per-skill instrument, and this fork already requires it
(`writing-skills/SKILL.md`). Tier 1 stays cheap and broad on purpose; making it half-realistic
would cost real money and still not be an eval.

Accepted cost: a skill that triggers in a tool-rich session but not under `--allowedTools Skill`
reads here as a miss. The script already treats a miss as "go read the description," never a
failure, and it always exits 0 — so the false-positive lands on a human's judgement, not on a gate.

## Revisit Trigger

- The fixture repo grows to where a realistic prompt requires reading it before acting.
- A skill is observed triggering in normal use but consistently missing in the probe, and the
  allowlist is the demonstrated cause rather than the prompt.
- `claude` gains a real turn or spend cap, which would make a wider allowlist bounded.
