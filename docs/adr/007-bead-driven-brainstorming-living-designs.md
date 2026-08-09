# ADR-007: Bead-Driven Brainstorming — Living Design Docs, Spec Content Moves Into bd

## Context

The brainstorming skill previously wrote a dated, point-in-time spec to
`docs/specs/YYYY-MM-DD-<topic>-design.md`, which `writing-plans` then decomposed into bd tasks. That
model sat awkwardly against the fork's beads-driven planning architecture (`docs/customizations.md`
describes brainstorming as having "beads work-decomposition woven through spine"): (1) `docs/specs/`
accumulates one file per session/change with no notion of "the current design of subsystem X" — there
is no single place to look for what a component's design *is* today, only a scattered history of
point-in-time proposals; (2) the spec content (requirements, acceptance criteria, trade-offs) lived in
a markdown file parallel to bd, duplicating information the epic should own instead.

Joe: "Our goal is to go to a completely bead driven development. So if the brainstorming skill creates
something new that requires a new design, it should be created. But if it updates a design, it should
update the design document that is in `docs/designs`."

An initial pass at this request only renamed `docs/specs/` to `docs/designs/` and swapped the word
"spec" for "design doc," keeping the dated-file-per-session model. Joe caught that this missed the
actual goal and prompted this ADR.

## Decision

1. **`docs/designs/` holds living, per-subsystem/component design docs** (`docs/designs/<topic>.md`,
   kebab-case, no date prefix) describing the system's *current* design. A change updates the
   relevant doc in place; it does not add a new dated file. `docs/specs/` is retired.
2. **Brainstorming checks `docs/designs/` before writing** (`ls`/grep, no index file — YAGNI): an
   existing doc for the area gets updated in place; a genuinely new subsystem gets a new file.
3. **The spec for a specific change — requirements, acceptance criteria, trade-offs — moves into the
   bd epic**, via `--description` (summary/why) and `--design` (detailed requirements/acceptance/
   trade-offs), created in Work Decomposition. This reuses the same `--design` field `writing-plans`
   already uses for per-task TDD detail, at the epic level.
4. **`--spec-id` on the epic still points at the relevant `docs/designs/<topic>.md` file** — a
   reference pointer to the living design the change is built on, not a claim that the file itself is
   the spec.
5. **record-decision's existing approach-selection trigger is unchanged** — it captures *why* a
   choice was made (ADR/decision doc), which is a different axis from *what the design is*
   (`docs/designs/`) or *what this change requires* (bd epic).

## Trade-offs

**Chosen: living per-subsystem `docs/designs/` + spec-in-bd**

- Gives a single, current-state reference per subsystem instead of a pile of point-in-time spec files
  nobody re-reads once the plan is written.
- Fully realizes bead-driven development — the spec for a change lives where the work is tracked, not
  in a parallel markdown artifact that can drift from the bd hierarchy.
- `--spec-id` + `--design` reuse existing bd fields rather than inventing new ones.

**Rejected: keep the dated `docs/specs/` file, just rename the directory**

- Was this ADR's initial implementation. A rename alone doesn't change the fact that specs still
  accumulate as disconnected snapshots instead of living documentation, and the change-specific spec
  content still lives outside bd.

**Cost accepted: "update in place" depends on correctly locating the relevant existing doc**

- No index file (`docs/designs/README.md`) tracks subsystem → doc mappings; discovery is `ls`/grep.
  Mitigated by naming design docs after the subsystem/component, keeping the mapping obvious from the
  filename. Revisit with an index if the number of design docs grows large enough that `ls`/grep stops
  being reliable.
