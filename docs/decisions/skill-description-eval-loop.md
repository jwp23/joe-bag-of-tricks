# Driving skill-creator's Description-Optimization Loop

## Decision

Description triggering is measured by driving Anthropic's installed **skill-creator** eval loop,
never by a harness of our own. Four choices make that concrete:

**Eval sets live at `.claude/eval-sets/<skill>.json`.** Authoring-only, alongside
`.claude/scripts/triggering-prompts/`, never shipped in either plugin. One JSON array of
`{"query", "should_trigger"}` per skill, 15-20 queries, roughly balanced.

**The loop runs on `claude-sonnet-5`.** `--model` is required and has no default.

**A compatibility shim, `.claude/scripts/skill-eval-shim/sitecustomize.py`, is fork-owned code
that carries a small derived fragment of skill-creator.** skill-creator advertises the description
under test by writing `.claude/commands/<probe>.md`; Claude Code 2.1.220 exposes that only as a
slash command, with no tool for the model to invoke it, so every query scores zero triggers. The
shim republishes the same probe as `.claude/skills/<probe>/SKILL.md` and hands off to the upstream
function. Roughly eight lines — the probe-file body and the `<skill>-skill-<id>` naming —
reproduce `run_single_query` because the two probes must carry identical descriptions for the eval
to mean anything. Source: `anthropics/skills`, `skills/skill-creator/scripts/run_eval.py`,
**Apache-2.0** per that skill's `LICENSE.txt`; attributed in the shim and in
`docs/customizations.md` as `docs/licensing.md` requires. The shim is deleted the day
skill-creator registers its probe as a skill.

**A candidate description is applied only if it beats the incumbent on the HELD-OUT TEST score.**
A tie is not a win — keep the incumbent.

`.claude/scripts/optimize-skill-description.sh` wraps all of it. It is an **on-demand tool, not a
gate** — the pre-commit floor in `.claude/rules/validating-changes.md` is unchanged. Procedure,
cost model, and conventions: `docs/skill-description-optimization.md`.

## Rationale

**Why skill-creator and not our own harness.** It already does everything a hand-rolled loop
would have to grow into — precision and recall in one eval set, three runs per query so a trigger
rate is stable, a 60/40 train/test split with test scores blinded from the rewriting model, and
selection by held-out score. It is installed, and `writing-skills/SKILL.md` already says to use
it. Building a second one would be `docs/adr/006`'s "Quorum, rebuilt worse" all over again.

**Why `.claude/eval-sets/`.** `docs/architecture.md` puts authoring tooling under repo-root
`.claude/` and forbids it shipping in a plugin. An eval set is input to a tool that lives outside
this repo entirely, so it is authoring data, not skill content — it must not sit beside the
`SKILL.md` it grades. Keeping the filename equal to the skill name is what lets the wrapper take
a bare skill name as its only required argument.

**Why sonnet.** The probe measures whether *a model* reaches for the skill, so the honest tier is
the one that runs these skills day to day. `verify-skills-load.sh` and
`probe-skill-triggering.sh` already use sonnet, so all three triggering-adjacent tools agree, and
a result from one is comparable with a result from another. `claude-haiku-4-5-20251001` is about
a third the cost and fine while iterating on an eval set, but a description tuned to haiku's
triggering is not evidence about sonnet's. Opus costs roughly 3x sonnet for a one-turn probe that
never gets past its first tool call — the extra capability is spent on nothing.

**Why a shim rather than a patch, a fork, or a copy.** Editing
`~/.claude/plugins/marketplaces/.../skill-creator` would be lost on the next plugin update and
would edit tooling this repo does not own. Vendoring skill-creator wholesale would put a copy of a
moving upstream under our maintenance for one stale line. The shim is ~60 lines that add a file
and delegate, of which ~8 are the derived probe-file format it has to match; it names its own
expiry condition.

**Why held-out test, and why a tie is not a win.** The train score is what the rewriting model
optimized against, so treating it as evidence is grading an exam against its own answer key. An
earlier draft of this decision broke ties by train score. That was wrong and is reversed:
`run_loop.py` strips every `test_*` key before handing history to the improver (L195-196) and
rewrites from the previous iteration's **train** failures (L203), so a higher train score is the
signature of one more round of fitting the train set — precisely what the holdout exists to
prevent. Upstream's own selection agrees: `max(history, key=test_passed)` (L218) returns the first
maximum, so on a tie the tool picks the **earliest**, least-fitted iteration. The proving run hit
this case — iterations 2 and 3 both scored 5/6 on test — and under the corrected rule neither
displaced the incumbent.

**What the proving run actually established.** That skill-creator as installed is unusable against
Claude Code 2.1.220 without the shim: 0/3 on all 18 queries, positives and negatives alike. The
candidate description was **not** adopted. 4/6 → 5/6 is one query, from one split of one run with
no repeats, well inside the triggering variance `docs/adr/006-defer-behavioral-evals.md`
documents; and the candidate also violated `writing-skills/SKILL.md` L217-235 (Description =
Capabilities + Triggers, NOT Process/Workflow) by carrying workflow instructions, one of which
described a research step `record-decision`'s body does not implement. The loop is worth having;
this particular result was not worth shipping.

**Why not a gate.** `docs/adr/006-defer-behavioral-evals.md` measured identical triggering
prompts flipping between runs and concluded a flaky blocking gate is worse than none. This loop
measures that same flaky thing, just with enough repetition to quantify it. At ~$6 and three
minutes a run it is also the wrong shape for a pre-commit hook. It answers a question you ask
deliberately: "this skill loads, so why is it firing on the wrong prompts?"

## Trade-offs

- The shim is a standing bet that skill-creator's registration mechanism stays broken. If
  upstream fixes it, the shim's double-registration is harmless (the command file it also writes
  is inert), but the file should be deleted rather than left to rot.
- Sonnet costs ~3x haiku for the same call count. The budget lever is `--max-iterations`, not the
  model, because dropping runs-per-query below 3 destabilizes the trigger rate and dropping below
  ~15 queries breaks the holdout.
- Spend cannot be measured locally: a triggering probe is killed before it writes a transcript,
  so `ccusage` reports a run that mostly triggers as free. Budgeting is by per-call estimate.
- Optimizing a `vendored` or `patched` skill's description creates hand-merge surface at the next
  upstream sync. Fork-original skills are preferred; anything else needs a row in
  `docs/customizations.md`.
