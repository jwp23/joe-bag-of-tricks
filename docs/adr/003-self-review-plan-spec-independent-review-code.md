# ADR-003: Inline Self-Review for Plan/Spec, Independent Subagent Review for Code

## Context

The fork inherited superpowers' review model, in which plan documents (writing-plans), spec
documents (brainstorming), and implemented code (requesting-code-review, subagent-driven-development)
were each reviewed by a freshly dispatched reviewer subagent.

The `v6.1.1` upstream sync surfaced empirical evidence against the **document** half of that model.
Upstream's commit `e6221a48` ("Replace subagent review loops with lightweight inline self-review")
reports: regression testing across five releases (v3.6.0–v5.0.4), five trials each, showed
**identical plan sizes, task counts, and quality scores whether or not the plan/spec reviewer
subagent ran** — the loop added ~25 minutes of overhead per run without measurably improving quality.
An inline self-review checklist caught 3–5 real bugs per run (spawn positions, API mismatches, seed
bugs, grid indexing) in ~30 seconds, with remaining defects comparable to the subagent approach.
Upstream applied the change, reverted it, and re-applied it the same day — it was deliberated, not
casual.

Separately, upstream's `strict-cost-sdd` campaign found the merged per-task reviewer holds quality at
**sonnet**, and explicitly **killed the haiku tier** (0/10 planted defects caught at correct
severity; the cheap model actively rationalized defects, e.g. praising a DRY violation as YAGNI).

Two questions for the fork: (1) keep independent-subagent review for plan/spec documents, or adopt
inline self-review? (2) what model tier should the SDD merged task-reviewer default to?

## Decision

1. **Plan/spec review → inline self-review.** `writing-plans` and `brainstorming` self-review their
   own documents with an explicit checklist (spec coverage, placeholder scan, type/internal
   consistency, scope, ambiguity) instead of dispatching a reviewer subagent. The now-unused
   `plan-document-reviewer-prompt.md` and `spec-document-reviewer-prompt.md` are deleted.

2. **Code review stays independent-subagent everywhere** — `requesting-code-review`,
   `receiving-code-review`, and the SDD per-task reviewer. The distinction is informational: a code
   reviewer reads a *diff* with genuinely fresh eyes and catches implementation blind spots; a plan
   reviewer has the *same information the author already has* (the spec plus the plan), so it is not
   meaningfully independent — which is exactly what upstream's trials measured.

3. **The SDD merged task-reviewer defaults to `sonnet`**, with escalation to opus for risky or
   security-sensitive diffs. Haiku is not used for review.

## Trade-offs

**Chosen: self-review for documents, independent review for code, sonnet task-reviewer**

- Removes ~25 min/run of plan/spec overhead the evidence shows buys no quality.
- Keeps independent review precisely where a fresh vantage adds signal (code diffs).
- sonnet is the validated cost/quality sweet spot; the opus-escalation net preserves rigor on the
  diffs that warrant it.
- Consistent with the fork's selective sync policy: adopt upstream where it's a genuine efficiency
  win, backed here by upstream's own regression data.

**Rejected: keep independent-subagent review for plan/spec documents**

- Was the fork's prior default and this ADR's initial recommendation ("rigor is the plugin's ethos").
- The 25-trial regression data shows no measurable quality benefit for document review — rigor
  without payoff is just latency and token cost.

**Rejected: push the task-reviewer to haiku for further savings**

- Upstream measured 0/10 planted-defect catches at haiku with active rationalization of defects.
  The judgment content of code review does not survive the cheaper tier.

**Cost accepted: self-review depends on author discipline**

- A self-review checklist relies on the author running it honestly. Mitigated by making the checklist
  explicit and concrete (the "No Placeholders" list, per-task Interfaces blocks for type consistency)
  rather than a vague "look it over."
