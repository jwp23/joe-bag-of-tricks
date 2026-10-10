# ADR-009: Brainstorming on Upstream v7's Conversational Spine; the Builder Check Replaces Spec Self-Review

## Context

Upstream superpowers v7.0.0 rebuilt `brainstorming` from scratch. The new skill draws out what the
human partner wants before proposing anything: an opt-out line plus one open question as the first
message, menus only when they are stuck, playback of each understood part in a few hundred words
with guesses marked as guesses, an early check on which how-it-gets-made choices (platform,
language, libraries, medium) they want to own, offers of recon and of spikes, wider just-in-time
triggers for the visual companion with a shorter offer, and work sized after understanding (quick
task / small change in chat / project with a written design). A **builder check** replaced the
spec-document reviewer: a fresh subagent reads the design as the person who will build it and
lists what they would still need to ask; brainstorming answers what it can, makes the minor calls
itself and marks them as its own, and brings the human the questions that change what gets built,
in one round. The how-it-gets-made rule came from a session that designed an iOS app, never asked
about platform, and built a web app (upstream #2482, #2483).

The fork's brainstorming (`replaced`) carried three paths — spike, bounded, architectural — plus
the bead-driven artifacts of ADR-007: living design docs in `docs/designs/`, the spec for a change
on the bd epic, and a handoff to `writing-plans` with the epic ID. ADR-003 had moved plan and spec
review to inline self-review on upstream's evidence that a document reviewer holding the same
information as the author adds ~25 minutes and no measurable quality.

Baseline (pre-edit text, text-fed `claude -p` probe): asked to design a plant-watering app in an
empty repo, the fork's first message classified the path aloud and asked a four-option
multiple-choice question; platform and language surfaced only at the approaches step.

## Decision

1. **Adopt upstream v7's text as the spine** of `brainstorming`, including its description wording
   (the fork keeps its plan-mode clause). The fork's artifacts are swapped in where upstream names
   its own: the written design is the living `docs/designs/<topic>.md` (ADR-007, unchanged), the
   spec for the change goes on the bd epic created in the work-decomposition step, a small change
   tracks one bd task, and a project hands off to `writing-plans` with the epic ID. Upstream's
   "Size the Work" table is the fork's three paths under other names, so the mapping is one to
   one; the fork's rule that a small change means an existing flow to change, its one-way
   step-up ratchet, its record-decision hook on approach selection, and its loaded-context clause
   (dispatch an implementer rather than build inline) are kept as sentences inside the new
   structure. The Plan Mode section is rewritten against the new structure.
2. **The builder check replaces the design self-review for project-sized work.** This narrows
   ADR-003 for *spec* documents. ADR-003's argument was that a document reviewer sees the same
   information as the author; the builder check deliberately does not — it reads only the document,
   cold, which is the test of whether the document stands alone for a planner who cannot ask. It is
   one dispatch and one round of questions. ADR-003's decision for *plans* (inline self-review in
   `writing-plans`) stands.

Post-edit, the same probe produced an opt-out line plus one open question, asked early who owns
the platform and language choice, and recorded a default it picked as its own call.

## Trade-offs

**Chosen: upstream's spine, fork's artifacts, builder check**

- Future syncs of brainstorming diff-merge far more cleanly: the fork's divergence is now a handful
  of named substitutions rather than a different document.
- The conversational improvements are measured upstream and reproduced here on the baseline probe.

**Cost accepted: one subagent dispatch per project design.** Bounded by one round; the human sees
only the questions that change what gets built.

**Rejected: port individual sentences into the three-paths document.** The fork's structure would
have fought upstream's at every section, and every future sync would re-fight it.

**Rejected: keep the inline design self-review alongside the builder check.** Two checks on the
same document, one of them the author's own, is the overhead ADR-003 measured as buying nothing.

> Supersedes ADR-003 in part (spec-document review); ADR-003's plan-review decision stands.
