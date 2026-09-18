# Bugs Route to a debugger Agent; Everyone Else Gets Stop Conditions, Not the Skill

## Decision

- Add a shipped `plugins/joe-bag-of-tricks/agents/debugger.md` — opus, high effort, the
  implementer tool allowlist, `skills:` preloading `implementer-contract` and
  `systematic-debugging`. It is the one agent that carries the root-cause procedure, and it is
  dispatch-shape-neutral: it takes a task brief or a failure description, works in the directory
  it is given, and reports in the implementer-contract format.
- Work known to be a bug is routed to it rather than to an implementer tier:
  - `subagent-driven-development`: a `-t bug` task dispatches to `debugger`, never to
    `implementer-mechanical`.
  - `dispatching-parallel-agents`: a `-t bug` batch item dispatches to `debugger`; when the
    parallel domains are failures to diagnose, each domain dispatches to `debugger` rather than
    `general-purpose`. Both rules live in the fork-owned section of that `patched` file.
- `implementer-mechanical` never debugs. On a failure it did not expect, or a brief that
  contradicts what it finds, it reports BLOCKED or NEEDS_CONTEXT at the first contradiction.
- `branch-shepherd` gains two stop conditions inside its bounded CI-fix loop: the failure cannot
  be reproduced locally, or a fix relocated the failure rather than resolving it. Either one ends
  the loop for that branch: it is reported BLOCKED with the diagnosis so far — naming the
  environment delta when the failure does not reproduce — and the train moves on. The
  orchestrator, which holds the Agent tool, dispatches `debugger` against a BLOCKED branch whose
  failure reproduces, then re-dispatches the shepherd for it.
- `implementer-contract` gains a verification-before-claiming rule, applying to every tier: a
  factual claim an implementer ships — in a code comment, a stated diagnosis, or a report — is
  one it observed by running the thing or reading the code it describes. A claim it only
  inferred is verified first or labelled as inferred.
- Rejected: **granting the shepherd the Agent tool so it dispatches `debugger` itself.**
- Rejected: **preloading `systematic-debugging` into the implementer tiers or the shepherd.**
- Rejected: **a procedure-path line in every sonnet/opus implementer dispatch.**
- Rejected: **a reviewer `defect` tag that sends fix round 2 to `debugger`** instead of resuming
  the original implementer. SDD's fix loop keeps its existing ladder.

## Rationale

- No subagent here holds the Skill tool, so "use systematic-debugging" reaches a subagent only by
  `skills:` preload, a path it Reads, or text the orchestrator inlines.
  `plan-steps-name-procedures-not-skills.md` already rejected preloading a per-task procedure
  into every implementer dispatch; nothing here overturns it. A dedicated agent is the
  `skill-editing-implementer.md` pattern: preload where the text applies to every dispatch of
  that agent, and route the work to it.
- The design was cut to what the record supports. Transcripts from `throwntom` and
  `swift-mutation-testing` on this machine (44 shepherd runs, 231 implementer runs, mined
  2026-09-18; six runs read closely, the rest classified from action sequences):
  - Both clear implementer thrash cases were haiku on the mechanical tier. One was a bug-fix
    task routed to mechanical: it guessed a cause from grep output without reading the source,
    shipped dead code, and reported DONE. The other hit a brief-mandated test that could not
    pass, rewrote it three times, then deleted it; the brief's premise was wrong.
  - The sonnet and opus implementer runs read were methodical, which is why the path-in-every-
    dispatch rule has no failing baseline and was dropped.
  - All 15 shepherd runs that hit a failure read logs before editing. The one substantive
    thrash (193 turns, three pushes, BLOCKED) was a CI/local toolchain skew visible before the
    first push returned; it patched one symptom per push. A run that stopped after one attempt
    ("my first attempted fix only relocated the error… I'll stop guessing") had been told to in
    its brief. The missing piece is the stop condition, not the four-phase procedure — and a
    stronger model would have met the same unreproducible failure.
  - Review findings reach a resumed implementer already diagnosed by the reviewer or controller,
    so a failed first fix round does not by itself show the implementer failed to diagnose.
  - The 8 implementer runs with two or more genuine review-fix rounds were classified by why
    round 1 did not close. Only 2 of the 8 surviving findings were runtime defects; in both, the
    round-2 message already carried the root cause, and round 2 closed on the same agent — one
    of them haiku. None of the 8 shows a round 3. A `debugger` at round 2 would have re-derived
    a diagnosis it had been handed, so the `defect`-tag rule has no failing baseline. ("Closed"
    here means no round-3 message plus the final status; re-review verdicts were not read.)
  - Where discipline would have helped those runs was round 1, and the shape was an agent
    asserting something it never ran: a call path guessed from grep output and shipped as a
    diagnosis (haiku), a code comment restating wording the agent never checked against the
    code (haiku), a row-invariance claim in a doc comment that was "measurably false" and never
    stress-tested (sonnet). That is a verification-before-claiming gap, not a missing debugging
    procedure, and it crosses tiers — hence a contract rule rather than more routing. The
    contract is already preloaded into every implementer dispatch, so the rule costs its own
    few lines and no new mechanism.
- Verified by throwaway probe on claude 2.1.276 (headless `claude -p`, one run each):
  - A subagent with `Agent` in its `tools:` can dispatch another subagent — the debug log shows
    `agent_completion agentType=probe:inner exitPath=completed`. The docs are silent on this.
  - The `Agent(<name>)` allowlist form does not scope a subagent's dispatches. Agents declaring
    `tools: Agent(probe:inner)` and `tools: Agent(inner)` each also dispatched `probe:other`,
    and the log shows both children completing. All four of those nested dispatches
    launched in the background, leaving the parent to report "completion notification pending";
    the single dispatch in the first probe returned synchronously. What decides between the two
    is unverified. So a
    shepherd holding `Agent` could dispatch anything in the roster and would have to wait on an
    async child — the shape behind its earlier stall on background loops. That is why the
    hand-off goes through the orchestrator.
  - A `skills:`-preloaded skill arrives with its `Base directory for this skill:` line and a
    substituted `${CLAUDE_SKILL_DIR}`, and the agent Read a sibling file by that path — so
    `debugger` can reach `root-cause-tracing.md` and the other supporting files.
- Cost accepted: one agent roster line against the gated context budget
  (`agent-roster-in-the-context-budget.md`), and an opus dispatch per bug.
- Every piece is a behavior change and owes the testing half of
  `.claude/rules/authoring-skills-and-agents.md`; the transcripts above are the documented
  baselines, each to be reproduced by fixture before its fix is written.
- Decided 2026-09-18 with Joe while brainstorming debugging discipline for subagents.
