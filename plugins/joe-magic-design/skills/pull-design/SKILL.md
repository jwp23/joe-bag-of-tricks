---
name: pull-design
description: Use when a codebase already has a visual identity — theme or token files, CSS custom properties, a Tailwind config, font declarations, icons, logos, screenshots — but no DESIGN.md, or when its DESIGN.md has drifted from the code. Pulls that existing design into a spec-conformant DESIGN.md (google-labs-code/design.md format, YAML tokens + prose) and points the project's CLAUDE.md at it. Not for inventing a design; refuses when no design artifacts exist.
---

# Pull Design

## Overview

What the code renders *is* the design. Every session that touches the UI re-derives it from
the stylesheets and gets it a little wrong; `DESIGN.md` does that derivation once, in a form
both people and agents read: YAML front matter with the exact token values, markdown prose with
the intent behind them. This skill writes that file from what already exists. It does not design.

`spec.md` in this directory is the format — token schema, section names and order, `omitted:`
syntax. Read it before writing; nothing here restates it.

## Sources

A token is worth recording only if you can point at where the code says it. Exact values come
from code: theme and token files (`tokens.json`, `theme.ts`, `_variables.scss`), CSS custom
properties, Tailwind/UnoCSS configs, `@font-face` and font stacks, component styles, native
theme code (SwiftUI, Flutter `ThemeData`, Compose). Logos, icons, and screenshots are read as
images: they confirm the palette in use, show the iconography, and give the Overview its
register. A value you cannot trace is an invention, and an invention is worse than an
`omitted:` entry — the linter catches a missing section; it cannot catch a plausible lie.

Two competing systems in one codebase (a half-finished migration, a legacy palette beside a new
one) are a question for your human partner, not an average. Averaging documents a design nobody
shipped.

## Output contract

- `DESIGN.md` at the project root. Front-matter tokens; `##` sections in the spec's order;
  `omitted:` with a reason for each section the code genuinely lacks.
- Prose written the way design.md's own philosophy asks: the Overview names a concrete reference
  the reader already knows (a broadsheet's business section, a hardware-store receipt, a 1970s
  lecture handout) rather than a string of adjectives; every color entry says what it is for and
  where it must not appear. A token table with no prose is a failed output even when it lints.
- One conditional pointer line in the project's `CLAUDE.md`, beside its other reference-doc
  pointers: read `DESIGN.md` before UI, styling, or component work, and lint it after editing
  it. Never `@DESIGN.md` — an import loads the whole file into every session.
- Gate: `npx @google/design.md lint DESIGN.md` exits 0 with zero errors. Fix warnings or justify
  them in the prose. Quote the lint JSON in your report; "it should pass" is not a result.

## Refusal

No artifacts in any source class and no images: write nothing, edit nothing, report what you
searched for. Framework defaults are not a design. A CLI's stdout format, help text, and error
messages are not a visual identity — documenting them under this heading is inventing a design
system for a project that has none.

## Red flags

| Thought | Reality |
|---|---|
| "I'll describe the feel; tokens can come later" | The front matter is the machine-readable half. Without it the file is prose with a lint warning. |
| "Editorial, warm, minimal" | Adjectives. Name the thing it looks like. |
| "This value looks right for the palette" | Not in a source file → not in the front matter. |
| "The CLI's output *is* its design" | That is the refusal case. Report the search and stop. |
| "`@DESIGN.md` so agents can't miss it" | It costs every session the whole file. One pointer line. |
| "Lint should pass" | Run it. Quote it. |
| "Both palettes are in use; I'll blend them" | Ask which is canonical. |
