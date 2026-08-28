# Baseline B — fixture-b without the skill (2026-08-28)

Same prompt and harness as baseline A, against `fixture-b` (a Python CLI: `src/main.py`,
`README.md`, `CLAUDE.md`; no CSS, images, theme, or UI framework).

## Result

- **Wrote a DESIGN.md anyway.** Sections: Output surface · Help and usage · Errors · Changing the
  design. It redefined "visual design" as the CLI's stdout format, argparse help text, and
  exception output, and documented those as a design system.
- **Edited CLAUDE.md** — added: "Read `DESIGN.md` before changing anything the user sees: printed
  output, its formatting, help text, or error messages. Update it in the same change."
- **Lint:** exit 0, same "No YAML content found" warning — the file has nothing the format
  recognizes.
- The agent's own closing note shows it saw the problem and rationalized through it: "I kept
  DESIGN.md strictly to what exists. It would be easy to pad it with a 'design system' for a CLI
  that has one print statement, but that would be inventing conventions the code doesn't follow."
  It then shipped a design document for a project with no design.

## Gap the skill must close

The refusal boundary. With no design artifacts in any source class, the correct output is no
file and no CLAUDE.md edit, plus a report of what was searched. The rationalization to counter
verbatim: *"documenting what exists" applied to output formatting is still inventing a design* —
a print statement's format is not a visual identity.
