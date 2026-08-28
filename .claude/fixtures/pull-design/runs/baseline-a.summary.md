# Baseline A — fixture-a without the skill (2026-08-28)

Prompt: "Create a DESIGN.md for this project that documents its existing visual design so both
people and coding agents can follow it, and make sure CLAUDE.md tells future sessions to read it
when relevant." Run via `claude -p --permission-mode acceptEdits` in a temp copy; no plugin loaded.

## Result

- **Lint:** exit 0, errors 0, warnings 1 — `"No YAML content found. Expected frontmatter (---) or
  fenced yaml code blocks."` The file is not in the DESIGN.md format at all: no front matter, so
  nothing is machine-readable. Exit 0 only because the linter has nothing to check.
- **Sections (actual):** Feel · Color · Typography · Spacing · Radius · Components · Known gaps
  (as-built, not intentional) · For coding agents. None of the spec's headings (Overview, Colors,
  Layout, Elevation & Depth, Shapes, Do's and Don'ts); order not the spec's.
- **Traceability:** good. Every hex value (`#1a1c1e #6c7278 #9e3826 #b8422e #f7f5f2 #ffffff`)
  is present in `styles.css` / `tailwind.config.js` / `logo.svg`. Nothing invented. It even
  noticed the hover color is hard-coded in CSS but named in Tailwind.
- **Images:** read both `logo.svg` and `screenshot.png`.
- **Prose:** competent but adjectival — "Editorial and paper-like: warm off-white page, serif body
  text, small uppercase monospace labels, a single terracotta accent." No concrete real-world
  reference. Color rules do say where clay must *not* appear ("don't use it for text, borders,
  or decoration") — that part meets the PHILOSOPHY.md standard.
- **CLAUDE.md:** one conditional pointer line under Reference Documents, naming the files to read
  it before touching. Not an `@` import. Correct.

## Gaps the skill must close

1. Format: YAML front matter with `colors` / `typography` / `spacing` / `rounded` / `components`
   tokens — the machine-readable half was entirely absent.
2. Spec section names and order.
3. Overview anchored to a concrete reference, not a string of adjectives.

## What was already right (do not over-specify)

Traceability, reading the images, the CLAUDE.md pointer shape.
