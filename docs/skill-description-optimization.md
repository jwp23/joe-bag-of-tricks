# Optimizing a Skill's Description

**On-demand deep tool. Not a gate.** Nothing in this repo blocks on it, and it is not part of
the pre-commit floor in `.claude/rules/validating-changes.md`. Reach for it when a skill loads
fine but you suspect it fires on the wrong prompts or misses the right ones — the exact gap
`docs/adr/006-defer-behavioral-evals.md` names as out of scope for the load gate, and the gap
`probe-skill-triggering.sh` only gestures at.

It runs Anthropic's **skill-creator** eval loop, which is already installed
(`example-skills@anthropic-agent-skills`). skill-creator itself is not vendored here — it is
Apache-2.0 and could be, but there is no reason to carry a copy of installed tooling. The one
exception is the compatibility shim, which reproduces ~8 lines of upstream's probe-file format
because it must match byte for byte to interoperate; that fragment is attributed in the file and
in `docs/customizations.md`.

## Run it

```
.claude/scripts/optimize-skill-description.sh record-decision --max-iterations 3
```

That wraps the upstream invocation, which is:

```
cd <fixture-with-a-.claude-dir>
PYTHONPATH=<skill-creator>:<shim-dir> SKILL_EVAL_SHIM=1 SKILL_EVAL_WORKROOT=<tmp> \
CLAUDE_CONFIG_DIR=<isolated-config> BROWSER=/bin/true \
python3 -m scripts.run_loop \
  --eval-set .claude/eval-sets/<skill>.json \
  --skill-path plugins/joe-bag-of-tricks/skills/<skill> \
  --model claude-sonnet-5 \
  --max-iterations 3 --runs-per-query 3 --num-workers 10 \
  --results-dir <dir> --verbose
```

`skill-creator` lives at
`~/.claude/plugins/marketplaces/anthropic-agent-skills/skills/skill-creator`. The module is
`scripts.run_loop`, run with `-m`, and the flags above are its real ones (`--eval-set`,
`--skill-path`, `--model`, `--max-iterations`, `--runs-per-query`, `--num-workers`,
`--trigger-threshold`, `--holdout`, `--description`, `--timeout`, `--report`, `--results-dir`,
`--verbose`). `--model` is **required**; `--holdout` defaults to `0.4` and `--report` to `auto`,
which opens a browser — the wrapper neutralizes that with `BROWSER=/bin/true` and keeps the HTML.

Run `scripts.run_eval` instead of `scripts.run_loop` to score one description without rewriting
it — **but not through the shim**: `python -m scripts.run_eval` re-executes the module as
`__main__`, so the patched copy is not the one that runs and every query scores zero.

## What the loop does

Upstream's, not ours: splits the eval set 60/40 train/test stratified by `should_trigger`, runs
every query three times for a trigger rate, rewrites the description from the **train** failures
only (test scores are blinded from the rewriting model), and selects the winner by **held-out
test** score. It stops early when every train query passes.

## Eval sets

One JSON array per skill at `.claude/eval-sets/<skill>.json` — authoring-only, never shipped
(`docs/architecture.md`). Each entry is `{"query": "...", "should_trigger": true|false}`.

- 15-20 queries, roughly balanced. Below that, a 40% holdout leaves too few test queries for the
  selection to mean anything.
- Positives should cover the phrasings a real prompt uses, not the skill's own vocabulary.
- Negatives are where the value is. Include near-misses that probe over-triggering — for
  `record-decision`, "should I use a for loop or map here", or a choice already settled by an
  existing ADR. Off-topic negatives pass trivially and teach you nothing.

## Model

`claude-sonnet-5`, and the wrapper defaults to it. The probe measures whether *a model* reaches
for the skill, so the honest choice is the tier that actually runs these skills day to day.
Sonnet is also what `verify-skills-load.sh` and `probe-skill-triggering.sh` already use, so all
three triggering-adjacent tools agree. `claude-haiku-4-5-20251001` is roughly a third the cost
and a reasonable choice while iterating on an eval set, but a description tuned to haiku's
triggering is not evidence about sonnet's. Opus is not worth ~3x sonnet for a one-turn probe.

## Cost

Measured per probe call on sonnet with a warm cache: ~3.5k cache-write + ~30k cache-read + a few
hundred output tokens, about **$0.036**. Calls = queries x runs-per-query x iterations, so
18 x 3 x 3 is 162 calls, about **$6**, in under three minutes wall clock at ten workers.

Spend is **not** locally measurable. `run_eval` kills each `claude -p` the moment the model
reaches for a tool, so a *triggering* session never writes a transcript and `ccusage` never sees
it — a run that mostly triggers looks free. Budget from the per-call figure, not from a usage
tool.

Cut cost by cutting iterations first; `--runs-per-query 3` is what makes a trigger rate stable
enough to act on, and shrinking the eval set below ~15 breaks the holdout.

## Applying a result

**Apply a new description only if it beats the current one on the HELD-OUT TEST score.** Equal or
worse means keep what you have — the train score is the thing the rewriting model optimized
against and is not evidence.

**A tie on test is not a win.** Do not break it by train score. That rule was written into an
earlier draft of this doc and is wrong: `run_loop.py` builds `blinded_history` by stripping every
`test_*` key (L195-196) and improves each iteration from the previous one's **train** failures
(L203), so a higher train score is the signature of one more round of fitting the train set —
exactly what the holdout exists to prevent. Upstream agrees: `max(history, key=test_passed)`
(L218) returns the *first* maximum, so on a tie the tool itself picks the **earliest**, least-fitted
iteration. Prefer the incumbent on a tie; if you must choose between two candidates, take the
earlier iteration, and if the tie actually matters, enlarge the eval set so the holdout can
separate them.

After applying, `claude plugin validate plugins/joe-bag-of-tricks` and
`.claude/scripts/verify-skills-load.sh --only <skill>`. A description containing `: ` or leading
quotes must be double-quoted in the frontmatter — an unquoted plain scalar with a colon silently
drops the whole frontmatter (see `systematic-debugging` in `docs/customizations.md`).

Prefer optimizing **fork-original** skills (`readme-sync`, `record-decision`, `security-review`,
`writing-agents`). Rewriting a `vendored` or `patched` skill's description creates hand-merge
surface on the next upstream sync, so it needs a row in `docs/customizations.md` justifying the
divergence. `writing-agents` is `disable-model-invocation: true` and never triggers by
description at all — optimizing it is meaningless.

## The shim, and why it exists

`.claude/scripts/skill-eval-shim/sitecustomize.py`. skill-creator advertises the description
under test by writing `<project>/.claude/commands/<probe>.md`. Claude Code 2.1.220 lists that
file under `slash_commands` only, never under `skills`, and exposes no tool for invoking a
project command — so the model cannot reach the probe and **every query scores 0 triggers**,
positives and negatives alike, which reads as "this description is catastrophically bad" rather
than "the harness is stale". Measured on the `record-decision` eval set: all 18 queries scored 0/3
triggers before the shim; with it, the current description scored 15/18 queries correct.

The shim wraps `run_single_query` so the probe is also written as a real skill at
`.claude/skills/<probe>/SKILL.md`, which is what skill-creator's own detector already matches on.
It modifies nothing under `~/.claude/plugins/` — the upstream function still does the work.

The probe body it writes is **derived from** upstream: the frontmatter block scalar, the heading,
and the `This skill handles: ...` line reproduce `run_single_query`'s `command_content`, and the
`<skill>-skill-<id>` naming and module-global `uuid` use are reproduced so the shim can predict
the name upstream will pick. Matching that format is a correctness requirement, not a copy of
convenience: the two probes have to carry identical descriptions for the eval to mean anything.
Source: `anthropics/skills`, `skills/skill-creator/scripts/run_eval.py`, Apache-2.0 per that
skill's `LICENSE.txt`. Attributed in the shim's docstring and recorded in `docs/customizations.md`
per `docs/licensing.md`.

Two non-obvious details are load-bearing:

- It is loaded as `sitecustomize`, not imported. `run_eval` fans out over a `ProcessPoolExecutor`
  whose workers re-import the module — Python 3.14 defaults to the `forkserver` start method on
  Linux, so a patch applied only in the parent is lost. Every interpreter imports `sitecustomize`.
- Each call gets a **private copy of the fixture**. Ten workers share one project root, and
  skills — unlike the command files upstream writes — are all visible to every concurrent session
  at once. Ten skills with identical descriptions and different names makes the model read one and
  invoke another, which the detector scores as a miss.

Delete the shim once skill-creator registers its probe as a skill upstream.

## Fixture and config isolation

The wrapper builds both, for reasons that are fixture bugs if you skip them:

- A **neutral fixture repo**, because run inside this repo a generic prompt is incoherent — a
  plugin repo has nowhere for a Postgres decision to land. Same lesson as
  `probe-skill-triggering.sh` and `docs/adr/006-defer-behavioral-evals.md`.
- An **isolated `CLAUDE_CONFIG_DIR`**, seeded from `~/.claude/.credentials.json`, because
  `joe-bag-of-tricks` is installed globally. Without it the real skill under test loads alongside
  the probe with a byte-identical description and the model picks one of the two.

`run_eval` builds its own `claude` command line, so `CLAUDE_CONFIG_DIR` is the only lever
available for either.

## Recorded runs

| Date | Skill | Model | Budget | Held-out before | Held-out after | Applied |
|------|-------|-------|--------|-----------------|----------------|---------|
| 2026-08-14 | `record-decision` | claude-sonnet-5 | 18 queries x 3 runs x 3 iterations | 4/6 | 5/6 | **no** — see below |

The first end-to-end run's real finding was about the harness, not the description: as installed,
skill-creator scores every query 0/3 against Claude Code 2.1.220 and is unusable without the shim.
That is what the run bought.

The candidate description was **not adopted**, for two reasons:

- **4/6 → 5/6 is one query, from a single split of a single run with no repeats.** Each query
  passes on triggers/runs >= 0.5 over three runs, so one query flipping 1/3 → 2/3 moves the
  headline. That is inside the run-to-run variance `docs/adr/006-defer-behavioral-evals.md`
  documents for triggering, and a six-query holdout cannot separate it from noise. Iterations 2
  and 3 tied at 5/6 on test; under the tie-break rule above, a tie is not a win.
- **The candidate violated `plugins/joe-bag-of-tricks/skills/writing-skills/SKILL.md` (L217-235):
  Description = Capabilities + Triggers, NOT Process/Workflow.** It carried "treat this as a cue
  to research and record the rationale now, not just explain it in chat" and "so it gets written
  down as an ADR or decision doc" — workflow instructions, in the field that is supposed to say
  when the skill applies. Worse, the skill body has no "research a past decision's rationale"
  step, so the description promised behavior the skill does not implement. A description that
  wins on triggering by describing a skill that does not exist is a regression, whatever the
  score says.

The shipped `record-decision` description is unchanged from `main`.
