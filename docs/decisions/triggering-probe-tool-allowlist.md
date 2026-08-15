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

Widening costs more, but the cost **is** boundable, and the decision does not rest on pretending
otherwise. `claude --help` (2.1.220) has no `--max-turns`, but it does have
`--max-budget-usd <amount>` — "Maximum dollar amount to spend on API calls (only works with
`--print`)" — and this probe runs `-p`, so it qualifies. `--tools` and `--permission-mode` are
there too, alongside `--allowedTools` / `--disallowedTools`. (The script's own `--timeout` is not
a `claude` flag; it wraps coreutils `timeout`, and caps wall-clock rather than spend.) So a wider
allowlist could be given a hard per-probe ceiling today, and any argument of the form "full tools
have no ceiling" is wrong.

What a spend cap does not buy is signal. This probe's entire output is which skill the agent
reached for — `jq` over the `Skill` tool_use in the stream — and that is decided on the first
turn. Every turn after the trigger is spend that produces nothing the report reads. Wide tools
purchase *execution* of the skill, which the probe does not grade; `--max-budget-usd` would then
truncate that execution mid-flight. The narrow allowlist is not a cost hack standing in for a
missing cap, it is the scope of the measurement: stop the session where the measurement ends.
A ceiling also caps the worst case without lowering the mean, and a post-sync sweep is
`--repeat 5` times however many skills drifted, so the mean is what the bill tracks.

The cost gap itself is real but the one number on hand is confounded, so it is cited as a prior
observation rather than a measurement of this axis. ADR-006 records `requesting-code-review`
dispatching a reviewer subagent, running ten turns, and hitting the 180s timeout at **$0.86** on a
single probe, against **$0.14** after the fix — but that fix was the *prompt* ("do NOT follow the
skill's instructions"), ADR-006's conclusion is "the cap has to be prompt-level," and the tool
configuration in effect for the $0.86 run is nowhere recorded. It shows that a workflow skill left
free to act gets expensive; it does not isolate tools from prompt. No clean tools-only datapoint
has been taken, and none was taken for this decision.

The read-only middle ground is the tempting one and it was rejected on evidence, not principle:
the fixture repo the probe builds is two files (`package.json`, `src/utils.js`). There is nothing
in it to read. Granting `Read`/`Grep`/`Glob` buys extra turns and extra spend in exchange for the
agent confirming what the prompt already told it. If the fixture ever grows into something a
realistic prompt would have to explore before acting, this is the first thing to revisit.

Prompt-level turn caps were rejected outright for this script, even though
`verify-skills-load.sh` uses one ("do NOT follow the skill's instructions") to keep its own cost
at $0.14. That works there because the load gate names the skill explicitly and only asks whether
it resolves. Here, instructing the agent to hold back is instructing it about the very decision
being measured — it contaminates the result. The prompt must stay a plain user request, so any
brake has to live outside the prompt. `--allowedTools` and `--max-budget-usd` both qualify; the
allowlist is chosen because it bounds the session by *scope* while the budget bounds it by
truncation, and a truncated session is the messier artifact to reason about.

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
- The probe is asked to report on what the agent *did* after triggering, not just which skill it
  reached for. That is a different instrument, it needs tools, and `--max-budget-usd` (which
  already exists) is the brake it should be given — cost is not the objection to that change.
