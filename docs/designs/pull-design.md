# pull-design

How a codebase's existing visual identity becomes a `DESIGN.md` that both humans and coding
agents read, and how the project is told to read it.

## The Problem

A project that already has a look — a theme file, CSS custom properties, a Tailwind config, a
logo, a set of icons — carries that look implicitly. Every agent session re-derives it from the
code, gets it partly wrong, and the drift compounds. The google-labs-code/design.md format fixes
the derivation once: YAML front matter holds the exact token values, markdown prose holds the
intent behind them, and a linter says whether the file is well-formed.

The skill's job is narrow: read what the code already renders and write it down in that format.
It does not design.

## The Plugin

`plugins/joe-magic-design/` is a separate, one-skill plugin, namespaced
`/joe-magic-design:pull-design`. It is not part of `joe-bag-of-tricks` because nothing in either
plugin references the other, and `joe-bag-of-tricks` is defined by its skills cross-referencing
as one unit. `joe-magic-bootstrap` is the precedent. Rationale and the rejected alternatives are
in `docs/decisions/pull-design-skill.md`.

```
plugins/joe-magic-design/
  .claude-plugin/plugin.json      # name, version, MIT (same shape as joe-magic-bootstrap)
  skills/pull-design/
    SKILL.md
    spec.md                       # vendored docs/spec.md from google-labs-code/design.md
```

`spec.md` is vendored verbatim (Apache-2.0; its generated-file header and an attribution note
are kept), with a row in `docs/customizations.md` and a paragraph in `NOTICE`. It exists so the
agent has the token schema and section contract without a network call. The linter's rules are
**not** vendored: the format is `alpha`, and `npx @google/design.md lint` tracks it.

## The Skill

`SKILL.md` is a generative skill: its output is an artifact, so it states goals, boundaries and
an output contract, not a procedure. It has three parts.

**Sources.** The design is what the code renders, not what a comment claims. Exact values come
from code: theme/token files (`tokens.json`, `theme.ts`, `_variables.scss`), CSS custom
properties, Tailwind/UnoCSS configs, font declarations and `@font-face`, component styles, native
theme code (SwiftUI, Flutter `ThemeData`, Compose). Images are read as images: logos, icons,
and screenshots give palette confirmation, iconography style, and the overall register the
Overview must describe. Every token in the front matter is traceable to one of these; a value
the agent cannot point at does not go in the file.

**Output.** `DESIGN.md` at the project root, in the spec's section order (Overview, Colors,
Typography, Layout, Elevation & Depth, Shapes, Components, Do's and Don'ts). Sections the
codebase genuinely lacks are listed under `omitted:` with a reason, not faked. The prose is
written to design.md's PHILOSOPHY.md standard: a concrete reference the reader already knows
("a broadsheet's business section", "a hardware store receipt") carries more than adjectives,
and each token's entry says what it is *for* and where it must *not* appear. A token table with
no prose is a failed output even if it lints clean.

Alongside the file, one conditional pointer line goes into the project's `CLAUDE.md`, next to
its other reference-doc pointers: read `DESIGN.md` before UI, styling, or component work, and
lint it after editing it. Never `@DESIGN.md` — an import loads the whole file into every
session.

**Gate.** `npx @google/design.md lint DESIGN.md` must exit 0 with zero errors. Warnings are
either fixed or justified in the prose (an orphaned `error` color that no component references
yet is a warning worth keeping, and the prose says so). The lint JSON is part of the report, so
"it should pass" cannot substitute for the output.

**Refusal.** A project with no design artifacts — nothing in the source classes above and no
images — gets no `DESIGN.md` and no `CLAUDE.md` edit. The skill reports what it searched for and
stops. Inventing a design from a framework's defaults is the failure this boundary exists to
prevent; a defaults-only project has no identity to document.

Where the code holds two competing systems (a half-finished migration, a legacy palette beside
a new one), the skill asks which one is canonical rather than averaging them. This is why it
runs in the main session and not as a forked subagent.

## Interfaces

| Boundary | Contract |
|---|---|
| In | A project checkout; optionally the human naming which of several systems is canonical |
| Out | `DESIGN.md` (spec-conformant, lint exit 0), one `CLAUDE.md` pointer line, the lint JSON in the report — or a refusal naming what was searched |
| Depends on | Node/`npx` and network for `@google/design.md`; the Read tool's image support for icons and screenshots |

A companion design-creating skill can hand this one a project whose artifacts it has just
produced; nothing in `pull-design` assumes that, and it needs no change to support it.

## Validation

The skill is tested the way `writing-skills` prescribes for generative skills: a baseline run
without the skill against a fixture, graded, then the same run with the skill.

- **Fixture A** — a small web project with CSS custom properties, a `tailwind.config.js`, an SVG
  logo, and a PNG screenshot. Grade: lint exit and findings, section order, every token
  traceable to a fixture file, prose quality against the PHILOSOPHY.md standard, and that the
  `CLAUDE.md` line is a pointer rather than an import.
- **Fixture B** — a project with source code and no design artifacts. Pass is a refusal that
  names what was searched and writes nothing.

Repo gates for the new plugin mirror `joe-magic-bootstrap`'s:
`claude plugin validate plugins/joe-magic-design`,
`.claude/scripts/verify-skills-load.sh --plugin-dir plugins/joe-magic-design`, and `betterleaks`.
`check-context-budget.sh` measures `joe-bag-of-tricks` only; a separate plugin spends none of
that budget, which is one reason it is separate. The plugin gets its own scoped
release tag, `joe-magic-design-v1.0.0`, on its version-bump commit.
