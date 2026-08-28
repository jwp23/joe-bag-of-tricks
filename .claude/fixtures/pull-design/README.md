# pull-design fixtures

Authoring-only. Used to test `/joe-magic-design:pull-design` the way `writing-skills` prescribes
for a generative skill: a baseline run without the skill, then the same run with it, graded.

- `fixture-a/` — "Ledger", a small web page with a real, consistent design: CSS custom properties,
  a `tailwind.config.js` carrying the same values, an SVG wordmark, and (after
  `./make-screenshot.sh fixture-a`) a `screenshot.png`. The skill must produce a DESIGN.md whose
  every token traces to one of those files.
- `fixture-b/` — "csvsum", a Python CLI with no design artifacts at all. The skill must refuse.

Runs copy a fixture to a temp dir and work there; never run against the fixture in place.
`runs/` holds captured outputs; everything in it is gitignored except the `*.summary.md` grades.
