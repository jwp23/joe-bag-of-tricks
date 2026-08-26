# Testing Agents With Subagents

**Load this reference when:** creating an agent definition, or making a behavior-changing edit to
one — before you write it, and again to verify it.

The cycle is the one in `testing-skills-with-subagents.md` (writing-skills directory): RED watch
it fail, GREEN watch it comply, REFACTOR close the loophole the fix opens. Read that file for the
cycle itself, pressure-scenario construction, and rationalization tables. This file covers only
what changes when the thing under test is an **agent**: it holds real tools, runs at a pinned
tier, and acts on a real repo — so the test needs a fixture and a sandbox, not just a prompt.

## When This Applies

A behavior-changing edit to a file under `agents/`: a new rule, bucket, gate, or escalation
trigger, or a relaxation of one. Not typos, not rewording. A **new** agent qualifies in full — its
whole body is new behavior, with no baseline yet showing what it has to fix.

## Build a Fixture First

Build it before you touch the agent. Its job is to make the question under test **checkable**
rather than a matter of opinion — the agent must be able to be wrong in a way you can demonstrate
from the repo, not merely disagree with.

Worked example: testing whether a review agent judges scope correctly needed a real git repo whose
branch touched only `tests/`, with the bug present at the merge base. "Is this finding in scope?"
was then answered by `git diff <merge-base>..HEAD -- <file>` returning empty — a command anyone can
re-run — not by the agent's taste.

Stack the pressures the skill-testing file describes into the fixture's situation (a release cut
in 40 minutes, a queue of branches, expensive CI), so the agent has a reason to want the shortcut.

Keep the fixture you build pristine and never dispatch against it directly — every run gets its
own copy, so runs cannot see each other's edits.

## RED — Dispatch the Previous Body

Baseline first: the body you are about to change *is* the previous body, so copy it aside before
you edit anything, and run the fixture against that copy.

```bash
WORK="$(mktemp -d)"                                   # scratch for this cycle's artifacts
cp -f plugins/joe-bag-of-tricks/agents/<agent>.md "$WORK/old-agent.md"

# Fallback, only if the change is already committed:
git show HEAD~1:plugins/joe-bag-of-tricks/agents/<agent>.md > "$WORK/old-agent.md"
```

Dispatch a subagent whose prompt names that file as its operating instructions — "your operating
instructions are in `$WORK/old-agent.md`; read it and follow it" — the file itself, never a
paraphrase.

**Creating a new agent?** There is no previous body, so the baseline is the same fixture and prompt
dispatched with no agent definition at all — plain-session behavior is the status quo the new agent
has to beat, and what it gets wrong is what the body must fix.

**How to dispatch.** A top-level session dispatches through the Agent tool. A session without one
— which includes every implementer agent here — uses a headless `claude -p` from Bash. Stream the
output as JSON so the probe is machine-readable rather than something you eyeball:

```bash
FIXTURE="$WORK/red"                                   # this run's own copy of the fixture repo
cp -rf <pristine fixture> "$FIXTURE"

env -C "$FIXTURE" claude --model sonnet --effort medium \
    --output-format stream-json --verbose \
    -p "$(cat "$WORK/dispatch-prompt.txt")" > "$WORK/red.jsonl"
```

Record the failure verbatim. The rationalizations it produces are the raw material for the counters
you will write — a failure you did not predict is the whole point of the phase.

Worked example: the pre-change `branch-shepherd` took no action at all on a finding the reviewer
had withdrawn — "not this shepherd's call" — and force-applied an out-of-scope change to the
fixture's `probe.sh` on the same run. Two documented failure modes, reproduced on demand.

## GREEN — Same Fixture, New Body

Write the fix, then re-run the identical fixture and prompt against the new body. **Give each run
its own copy of the fixture**: the agent edits files, so a second run in a used directory is
testing a repo the first run already changed.

Judge by what the agent did to the fixture — `git status`, `git diff`, the files it wrote — not
only by what its report claims it did.

## REFACTOR — Close the New Rationalization

The fix will open a new rationalization. Go looking for it before you ship.

Worked example: once the DEFER bucket existed, every agent in the GREEN run deferred a finding it
had never established was correct — one of them while voicing doubt about it. Deferring was cheaper
than judging, so the new bucket had become the cheap escape the old one used to be. The counter was
an explicit correctness floor (judge correctness first; unsure resolves to reject or escalate,
never to defer). Re-running confirmed it held: both agents rejected the checkably-false finding on
correctness, and across all four post-refactor runs the out-of-scope bug still deferred and the
in-scope nit still applied — so the floor cost nothing the original fix cared about.

## HARD SANDBOX RULES — Mandatory, Not Optional

An agent under test holds real tools and will use them on your actual repo. Every dispatch prompt
must carry rules that **override the agent's own instructions**:

- Operate only inside the fixture directory. Nothing outside it may be read or written.
- Never run `gh`, or `git push`, `pull`, `merge`, `checkout`, `rebase`, `reset`, or `worktree`.
- State what you would have done instead of doing it, for anything the rules above forbid.
- One fixture copy per run, so runs cannot see each other's edits.
- These rules propagate: pass them on verbatim to anything you dispatch yourself. An agent that
  obeys them and hands a nested subagent an unrestricted prompt has not contained anything.

Not belt-and-braces: `branch-shepherd`'s own body instructs it to push, open PRs, and squash-merge.
Without the override it does exactly that.

## Dispatch at the Agent's Pinned Tier

Read `model:` and `effort:` from the agent's own frontmatter and pass them — `--model` / `--effort`
on the CLI; the Agent tool exposes `model` only, so a dispatch through it cannot match a pinned
`effort`. An agent pinned to sonnet, tested on opus, proves nothing about how it will actually run
— a stronger model reasons its way out of a trap the shipped tier falls into.

## The Negative Case Must Be Checkably False, Not Merely Unwise

This is the mistake that costs the most rounds. A suggestion that is *poor advice* is one a careful
agent may reasonably accept, so it cannot isolate a bucket-choice rule.

Worked example: isolating the DEFER correctness floor took three fixture attempts, and the two
failures are the useful part. Both offered findings that were merely poor advice — defensible
readings of the code — so both were reasonably deferred, and neither tested what it was built to
test. The attempt that worked described a `REPORT_DIR` assignment on line 11 of a nine-line file:
one `Read` disproves the premise, leaving no defensible bucket but reject.

## Cost

Budget roughly $0.15–0.25 per dispatch at sonnet, and expect a full RED/GREEN/REFACTOR cycle to
take a handful of dispatches per agent — more when a fixture attempt fails to isolate anything,
which it will. Plan for a couple of dollars and a half-hour of wall clock, not for one run. These
are planning figures; measure your own.
