# pull-design: an Extract-Only DESIGN.md Skill in Its Own Plugin

## Decision

A new skill, `pull-design`, ships as the single skill of a third, separate plugin,
`plugins/joe-magic-design/`, namespaced `/joe-magic-design:pull-design`. It mines the design a
codebase already expresses — theme and token files, CSS custom properties, Tailwind configs,
font declarations, component styles, icons, logos, and screenshots read as images — and writes a
`DESIGN.md` in the google-labs-code/design.md format: YAML front-matter tokens plus prose sections
in the spec's canonical order. It then adds one conditional pointer line to the project's
`CLAUDE.md` (read `DESIGN.md` before UI, styling, or component work; lint it after editing it).

Four boundaries are deliberate:

- **Extract-only.** When a project holds no design artifacts, the skill stops and names what it
  looked for. It does not interview the human and does not invent a design. Greenfield design is
  another skill's job; this one documents what exists.
- **The official linter is the only gate and the only runtime dependency.** The produced file
  must pass `npx @google/design.md lint DESIGN.md` with zero errors. The eleven rules
  (`broken-ref`, `contrast-ratio`, `section-order`, `orphaned-tokens`, …) are not re-stated in
  the skill; the spec is `alpha` and the linter tracks it.
- **The spec is vendored, the rules are not.** `docs/spec.md` from google-labs-code/design.md
  (Apache-2.0) ships beside the skill as `spec.md` so an agent has the schema and section
  contract without a network call. Its notice is preserved and it has a row in
  `docs/customizations.md`.
- **`DESIGN.md` is the only artifact.** No `export --format css-tailwind` / `dtcg` output: the
  codebase already holds its real theme, and a generated copy is a second source of truth that
  drifts.

## Rationale

- Own plugin, not a `joe-bag-of-tricks` skill: `pull-design` references no skill in that plugin
  and nothing there references it, so it fails the "cross-references, ships as one unit" test that
  defines that plugin. `joe-magic-bootstrap` is the precedent for a one-skill sibling plugin, and
  a separate plugin leaves `joe-bag-of-tricks`'s always-loaded context budget untouched.
- Conditional pointer over `@DESIGN.md` import: an import force-loads the whole file into every
  session, and a token table alone can run past a hundred lines. A pointer costs nothing until
  UI work starts, and matches how this repo lists its own reference docs.
- Prose skill, no extractor script: the artifact surface (CSS, Tailwind, SwiftUI, Flutter,
  `tokens.json`, PNG/SVG) is too varied for a grep-based extractor to be more than a web-only
  special case, and an extractor is exactly the kind of brittle helper that becomes a maintenance
  surface. Revisit only if testing shows the agent producing bad tokens from web projects.
- Not forked (`context: fork`): a pull that finds two competing palettes should be able to ask.
  Forking is a one-line frontmatter change if context blow-up on large codebases shows up in use.
- design.md's own PHILOSOPHY.md is explicit that prose, not tokens, carries the design — a
  concrete reference ("a 1970s graduate lecture handout") beats a list of adjectives. The skill
  is written to that standard, and the quality grade in testing is on the prose, not just on
  linter exit.
- Cost if wrong: a third plugin to version, tag, and validate (one more `claude plugin validate`
  line and one more `verify-skills-load.sh --plugin-dir` line in the gate). Accepted; the cost is
  identical to what `joe-magic-bootstrap` already carries.
- Measured 2026-08-28 (`.claude/fixtures/pull-design/runs/*.summary.md`). Fixture A, baseline:
  lint 0 errors / 1 warning ("No YAML content found") — no front matter, eight non-spec
  headings, adjectival Overview, 0 untraceable tokens, CLAUDE.md pointer line. With skill:
  lint 0 / 0, eight spec sections in order under token front matter, Overview anchored to a
  concrete reference, 0 untraceable tokens, pointer line. Fixture B, baseline: wrote a
  DESIGN.md about stdout formatting and edited CLAUDE.md; with skill: refused, wrote nothing,
  named the source classes searched. One harness iteration (the `-p` session needed
  `--add-dir` for the plugin's `spec.md` and `npx` allowed); zero skill-text iterations.
