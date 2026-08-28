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

## Run 3 — after the final review removed the example references — PASS

The final review noted that run 2's Overview ("business pages of a broadsheet newspaper") matched
the first of three example references then listed in SKILL.md, so the anchored-Overview evidence
could have been pattern-matching. The examples were removed and A re-run.

- **Overview:** "Ledger looks like a page from a well-set financial annual report: a serif
  headline on warm off-white stock, small-caps-style monospace metadata above it, white content
  panels ruled with a thin grey line, and one brick-red action." A different, unseeded, concrete
  reference; audience and tone still named.
- **Lint:** exit 0, errors 0, warnings 1, infos 1. The warning is `contrast-ratio` on
  `button-secondary`: the linter reads `transparent` as `#00000000` and computes 1.23:1. The
  output justifies it in the Components prose ("renders on the limestone page, where ink text is
  far above WCAG AA") rather than faking a fill — the contract's "fix or justify" path.
- Sections, traceability (same six hex values), images read, CLAUDE.md pointer line: as run 2.

## Against baseline A

Baseline: no front matter (lint "No YAML content found"), eight non-spec headings, adjectival
Overview. With skill: full token front matter, spec headings in order, reference-anchored
Overview, zero warnings. Traceability and the CLAUDE.md pointer were already right in the
baseline and stayed right.
