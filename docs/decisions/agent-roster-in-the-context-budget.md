# The Agent Roster Is Gated Surface, Counted Like Skill Descriptions

## Decision

- **`check-context-budget.sh` gains a third gated tier, `agents`.** It counts the plugin's own
  lines in the Agent tool's roster, which the harness injects as a `<system-reminder>` at the
  top of **every** session. Skill descriptions were already gated for exactly this reason; an
  agent's name, description, and tool list are the same kind of cost and were invisible.
- **Only the plugin's lines are counted.** The roster's header, the built-in agents (`claude`,
  `Explore`, `general-purpose`, `Plan`, `statusline-setup`), and the trailing concurrency note
  are present whether or not this plugin is installed, so they are not this plugin's cost. Tier
  1 already draws the line the same way — it counts skill description lines, not the
  available-skills header.
- **`BUDGET` rises 3,900 → 4,771.** That is `3,900 + 871`, where 871 is the measured cost of the
  seven agent roster lines **as they already exist**. Headroom is therefore unchanged at 423
  tokens. This raise recognises surface that predates the tier; it buys room for nothing new,
  and it is not a way to make the gate pass.
- **Every future agent now spends measured budget**, and `writing-agents` says so at the point
  where a description gets written. That is the cost of the decision, accepted deliberately: 423
  tokens of headroom are now shared between the next skill and the next agent.
- **The gate refuses to measure what it cannot render faithfully.** A `name:`, `description:`, or
  `tools:` value that is a folded or block scalar, or a block-style list, leaves the key's line
  empty and fails the run with the file named rather than being measured as empty. A flow-style
  `tools: [Read, Grep]` is refused by name, being the same class in the other YAML spelling.
  `disallowedTools:` — which the harness renders as "All tools except …", and as a set difference
  when combined with `tools:` — is refused outright, because no agent here uses it and modelling
  it from an unexercised code path would be a guess. An agent with no `tools:` key is rendered
  `(Tools: All tools)`, which is the harness's documented default and its observed behaviour.
- **A comma-separated `tools:` is normalised to `", "` before counting.** The harness parses the
  allowlist and re-joins it, so `tools: Bash,Read` is injected as `(Tools: Bash, Read)` and costs
  what the spaced spelling costs. Counting the raw string would under-report — the one direction
  a budget gate must never round.

## Rationale

**The format was verified, not assumed.** Counting against an invented shape would have produced
a confident number that measures nothing. Two independent pieces of evidence, both reproducible:

- *The harness's own renderer.* In `claude` 2.1.220 (`/opt/claude-code/bin/claude`) the roster
  line is built by one function, which after minification reads:

  ```js
  function iAd(e,t){let r=B8y(e),n=t&&e.whenToUseLean||e.whenToUse;
    return `- ${e.agentType}: ${n} (Tools: ${r})`}
  ```

  with the tool phrase from `B8y`: the allowlist joined `", "`; `All tools except <denylist>`
  when only a denylist is set; `All tools` when neither is. The block is assembled under the
  header `Available agent types for the Agent tool:` and delivered as an `agent_listing_delta`
  attachment — a `<system-reminder>`, `isMeta: true`, sorted by agent type.

- *A real session's request body.* Pointing `ANTHROPIC_BASE_URL` at a local server that logs the
  POST body and returns 400, then running
  `claude --plugin-dir plugins/joe-bag-of-tricks -p …`, captures what the harness actually sent.
  The seven `- joe-bag-of-tricks:*` lines the new tier generates are **byte-identical** to the
  seven in that captured system prompt. That is the check to repeat if the harness ever changes
  the format; it costs no model call, because the request never reaches the API.

  The same capture, run again with three throwaway agent files, is where the `tools:` rules come
  from — they are observations, not readings of the minified source:

  ```
  tools: Bash,Read      → (Tools: Bash, Read)     # parsed and re-joined with ", "
  tools: [Read, Grep]   → (Tools: Read, Grep)     # flow list, elements rendered
  tools: []             → (Tools: All tools)      # empty list reads as "no allowlist"
  ```

**Gated, not merely reported.** The tier could have been informational like `bodies`. It is not,
because the roster is paid on every session before the user has said anything — the same
property that makes tier 1 a gate. A reported-only number would be read once and then drift,
which is the situation this decision is fixing: the adjudicator agent was added with the gate
reporting a total that did not move by a single token.

**This is why the adjudicator's triggers live in the skills.** `adjudicator-as-shared-agent.md`
already reasons about the roster — "the orchestrator never reads an agent's body — it sees only
the roster's name, description, and tool list" — and spends that budget knowingly. The gate now
measures what that document was reasoning about.

**Cost if wrong.** The tier under-reports if the harness starts rendering agents differently (a
lean description variant already exists in the code for small main-loop models, and this gate
measures the full one at `claude-opus-5`, which is the right side to gate on). It over-reports
nothing. The failure mode is a budget that is slightly too tight, not one that silently permits
growth.

## Revisit Trigger

- The captured request body stops matching the lines the gate generates — the harness changed
  the roster format.
- An agent needs `disallowedTools`, a list-valued `tools:` in either YAML spelling, or a
  frontmatter value that genuinely has to be a block scalar. All hard-fail with a named file;
  extend `tools_for` / `frontmatter_scalar` then, rather than loosening them. The rendering to
  match is already measured — see the capture above.
- Headroom runs out. The next decision is which surface to shrink — a skill description, an agent
  description, or the `using-skills` injection — and only then whether the budget is wrong.
