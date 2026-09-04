# authoring-beads as a fork-original skill

## Decision

Add `skills/authoring-beads` to `plugins/joe-bag-of-tricks`: a fork-original skill for authoring
ONE well-formed ad-hoc bead (a GitHub issue, a stray idea, a discovered bug) outside the
brainstorming → writing-plans pipeline. Adapted from a private predecessor skill written for
another project (parked at `future-skills/authoring-beads/`; same author, no external license),
with these deliberate changes:

- **Source-project machinery stripped**: the polecat-runnable vocabulary, the
  `merge_strategy=automerge` metadata stamp (a gas-city pipeline artifact), and the
  gcloud/Grafana autonomy-enabler tables.
- **Conventions conformed to the plugin's existing skills**: `--parent` for hierarchy and
  `bd dep <blocker> --blocks <blocked>` for ordering (per writing-plans), `--acceptance` for
  criteria (per brainstorming). The predecessor's `bd dep add` direction-trap section dissolves
  under the self-documenting `--blocks` form.
- **Scoped to a single bead**: epic-sized work hands off to brainstorming → writing-plans rather
  than outlining children in-skill, so the plugin keeps one decomposition path.
- **Autonomy-first retained, generalized**: beads default to autonomous bead-crunch execution;
  `human-decision` / `human-run` labels are the exception, applied only after a one-time probe
  for a tooling alternative.
- **Aligned with writing-plans' No Placeholders**: bead bodies never instruct "invoke skill X" /
  "run /command" — crunch agents have no Skill tool; name the procedure's file instead.

## Rationale

The plugin had exactly one bead-creation channel (brainstorming epic → writing-plans tasks) and
nothing for "file one good bead from this GitHub issue". Freeform `bd create` was the fallback,
and the baseline test (writing-skills RED phase, 2026-09-03) showed what that produces under
time pressure: a vague intermittent bug filed as actionable P1 with zero questions asked, a
fabricated notification subsystem (and placeholder GitHub URL) the fixture codebase doesn't
contain, and a skill-invocation step in the bead body. The skill closed all of these in the
GREEN run: triage stub with TBD acceptance, codebase read before drafting (the missing subsystem
became the central triage question), no constructed URL, default P2.

Trade-offs accepted: +76 tokens on the always-loaded description surface (within the existing
budget; no `BUDGET` raise needed), and a second skill that talks about bead fields — accepted
because merging it into brainstorming or writing-plans would bloat skills whose triggers
("let's build X" / "here's a spec") are disjoint from this one's ("file this issue as a bead").
