# With skill A — fixture-a with `/joe-magic-design:pull-design` (2026-08-28)

Prompt: "Use /joe-magic-design:pull-design on this project." Run via `claude -p --plugin-dir
plugins/joe-magic-design --permission-mode acceptEdits` in a temp copy of `fixture-a`.

## Run 1 — harness failure, not a skill failure

The agent invoked the skill, inventoried all five artifacts, traced every token to
`styles.css`/`tailwind.config.js`, read `logo.svg` and `screenshot.png`, correctly judged "one
consistent design, not the refusal case" — then stopped without writing: the non-interactive
session denied `Read` of the plugin's `spec.md` (outside the temp cwd) and `npx`. It refused to
write against a schema it had not seen ("Writing DESIGN.md against a schema I haven't seen would
be inventing technical details"). That refusal is the right behavior; the fix is in the harness:
`--add-dir <plugin root>` and `--allowedTools` including `Bash(npx *)`, which an interactive
session grants by prompt.

## Run 2 — PASS

- **Lint:** exit 0, errors 0, warnings 0, one info (`token-summary`: 6 colors, 5 typography
  scales, 2 rounding levels, 6 spacing tokens, 6 components).
- **Sections:** Overview · Colors · Typography · Layout · Elevation & Depth · Shapes ·
  Components · Do's and Don'ts — the spec's eight, in order, under YAML front matter
  (`version: alpha`, `name: Ledger`).
- **Traceability:** every hex value (`#1a1c1e #6c7278 #9e3826 #b8422e #f7f5f2 #ffffff`)
  present in the fixture's `styles.css` / `tailwind.config.js` / `logo.svg`. Token names follow
  the spec's recommended roles (`primary`, `secondary`, `tertiary`, `neutral`, `surface`) with
  the code's names kept in prose ("Ink / Primary").
- **Images:** read `logo.svg`, `screenshot.png`, and the plugin's `spec.md`.
- **Prose:** Overview opens with a concrete reference — "the business pages of a broadsheet
  newspaper laid on an off-white desk" — and names audience and emotional target. Each color
  entry states use and prohibition ("Do not use clay for text, borders, links, or as a
  'warning' tint"; "never use [limestone] as a card fill").
- **CLAUDE.md:** one line added under Reference Documents: "DESIGN.md — read before UI, styling,
  or component work; after editing it, run `npx @google/design.md lint DESIGN.md`". Not an
  `@` import.

## Against baseline A

Baseline: no front matter (lint "No YAML content found"), eight non-spec headings, adjectival
Overview. With skill: full token front matter, spec headings in order, reference-anchored
Overview, zero warnings. Traceability and the CLAUDE.md pointer were already right in the
baseline and stayed right.
