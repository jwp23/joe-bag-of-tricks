# Gold-Standard Example Set

Target quality bar for a generated CLAUDE.md + `.claude/` structure: progressive disclosure, command-over-prose, imperative rules, skill invocation, and a combined footprint near 200 lines. Match this quality when generating a project's files; never reproduce this content verbatim into someone else's project.

This set shows the bar: progressive disclosure, command-over-prose, imperative rules, skill invocation, and a combined footprint near 200 lines. Match this quality; do not reproduce its content. The specific tools and skill names used below (bd, systematic-debugging, record-decision, finishing-a-development-branch, test-driven-development) are illustrative placeholders, not defaults — don't assume the target project uses any of them; substitute whatever the project actually has.

## `CLAUDE.md`

~~~markdown
# PDF Text Overlay Editor

A desktop GUI application for Linux that opens PDF documents, renders pages visually, and lets users click anywhere on a page to place text overlays. Users control font and font size. The result is saved as a new PDF with text baked in.

@AGENTS.md

## Tech Stack
Rust (edition 2024) desktop GUI: Iced 0.14 (wgpu/Wayland); `pdftoppm` rendering; `lopdf` writing; `fc-list` fonts; `rfd` dialogs; `cargo test` + `rustfmt`/`clippy`; GitHub Actions CI.
Full stack detail and per-choice rationale: see `docs/tech-stack-docs.md` and `docs/adr/` (see Reference Documents).

## Decision Recording
Recording technical decisions: see `@.claude/rules/decision-recording.md`.

## What This Project Does
- Opens and renders PDF pages in a desktop GUI
- Lets users click on a rendered page to position a text cursor
- Users type text that overlays the original PDF content
- Users can select font family and font size
- Saves the result as a new PDF with overlaid text embedded

## What This Project Does NOT Do
- Does NOT edit, modify, or extract existing text in the PDF
- No annotations (highlights, sticky notes, drawing, markup)
- No multi-user or collaboration features
- No cloud storage, network features, or remote file access
- Form-filling is not in initial scope (may be evaluated later — record as ADR if pursued)

## Linux System Utilities
The project uses these system utilities instead of pure-library alternatives:
- `pdftoppm` (poppler-utils) — PDF page rasterization
- `fc-list` (fontconfig) — discover installed system fonts
Each utility has a trait-based wrapper module for testability. See ADR-004.
When calling system utilities: use `std::process::Command` (never shell). Wrap failures with clear error messages stating what tool failed and how to install it.

## Code Style
Five mandatory principles — human readable, loosely coupled, idiomatic, simple, professional. Details and anti-patterns: see `@docs/code-style-guide.md`.
When style conventions and simplicity conflict, simplicity wins.

## Testing
### Test Pyramid (Mandatory)
- **Unit tests**: Cover all public methods and functions
- **Integration tests**: Cover how components work together
- **End-to-end tests**: Cover user workflows (open PDF → place text → save)
Unit tests use trait-based test doubles for system boundaries and must pass without external utilities installed. Integration tests go in `tests/`, marked `#[ignore]` when they require system utilities; CI runs them with `cargo test -- --ignored`.
### TDD (Mandatory)
Use red/green TDD for every feature/bugfix — see `@.claude/rules/tdd.md`.
### Test Framework
`cargo test`. Unit tests co-located in `#[cfg(test)]` modules. See ADR-005.

## Git Workflow
- **Commits**: Conventional Commits, single line only. No body, no footer.
- **Lockfiles**: Always commit lockfiles regardless of language/package manager.
See `@.claude/rules/git-workflow.md` for branch naming, PR workflow, worktrees, and merge policy.

## Pre-commit & CI
Pre-commit hook runs: `betterleaks git --pre-commit --staged --redact` (hard fail) · `cargo fmt --check` · `cargo clippy -- -D warnings` · `cargo audit` · `cargo test`.
GitHub Actions CI runs secret scanning, the same Rust checks, plus `cargo test -- --ignored`.
See `@docs/decisions/pre-commit-suite.md` and `@docs/decisions/ci-pipeline.md`.

## Reference Documents
**IMPORTANT:** Before starting any task, identify which docs below are relevant and read them first. Load the full context before making changes.
- `docs/code-style-guide.md` — Read when writing or reviewing code. Examples and anti-patterns for the five style principles.
- `docs/adr/*.md` — Read when making a decision related to an existing ADR.
- `docs/decisions/*.md` — Read when working in an area covered by an existing decision.
- `docs/decision-recording.md` — Read when recording a technical decision. ADR/decision-doc formats and numbering.
- `docs/architecture.md` — Read when navigating the module map or modifying component boundaries or data flow.
- `docs/tech-stack-docs.md` — Read when working with a library/framework API or needing docs for a dependency.

## Project Structure
Module map: see `docs/architecture.md` (read when navigating or modifying modules).
~~~

## `AGENTS.md` (imported at the top of CLAUDE.md — note command-over-prose and the environment-quirk gotchas)

~~~markdown
# Agent Instructions

## Non-Interactive Shell Commands
**ALWAYS use non-interactive flags** with file operations to avoid hanging on confirmation prompts.
Shell commands like `cp`, `mv`, and `rm` may be aliased to include `-i` (interactive) mode on some systems, causing the agent to hang indefinitely waiting for y/n input.
**Use these forms instead:**
```bash
# Force overwrite without prompting
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file
# For recursive operations
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest
```
**Other commands that may prompt:**
- `scp` - use `-o BatchMode=yes` for non-interactive
- `ssh` - use `-o BatchMode=yes` to fail instead of prompting
- `apt-get` - use `-y` flag
- `brew` - use `HOMEBREW_NO_AUTO_UPDATE=1` env var

## Session Completion
This project uses a PR-based workflow. See `.claude/rules/git-workflow.md` for the authoritative procedure; never push directly to main.
~~~

## `.claude/rules/debugging.md`

~~~markdown
# Systematic Debugging
YOU MUST ALWAYS find the root cause of any issue — never fix a symptom or add a workaround.
FOR ANY DEBUGGING TASK, YOU MUST invoke /systematic-debugging via the Skill tool before reading code or proposing fixes.
~~~

## `.claude/rules/decision-recording.md`

~~~markdown
# Decision Recording Rules
Before any technical decision, classify it as an ADR or a decision doc and ALWAYS ask which to use before recording. Never make a significant technical choice without recording it.
YOU MUST invoke the `record-decision` skill via the Skill tool for the process; see `docs/decision-recording.md` for formats and numbering.
~~~

## `.claude/rules/git-workflow.md`

~~~markdown
# Git Workflow Rules
## Feature Branches Only
Never commit directly to main. All changes go through feature branches and pull requests.
Branch naming: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, `test/` + short description.
## Worktrees
For extensive changes, use git worktrees in `.worktrees/` (project-local, hidden). Always use this location — do not ask.
## Completing Work
When implementation is complete and tests pass, YOU MUST invoke the `finishing-a-development-branch` skill via the Skill tool — it dispatches the pr-creator agent for push/PR/CI; the pr-merger agent handles approved merges.
## Merge Policy
Merges use squash with no body, and delete the branch on merge.
## Session Completion
Use the PR-based workflow above; never push directly to main. Work is complete only when the PR is open and CI is green; PRs never merge without passing CI.
~~~

## `.claude/rules/testing.md`

~~~markdown
# Testing Rules
## Test Pyramid
- **Unit tests**: Every public function and method must have tests. Test edge cases and error paths.
- **Integration tests**: Cover every component interaction; mock external dependencies (system utilities, file I/O) at integration boundaries.
- **E2E tests**: Cover the core user workflow: open PDF → place text → configure font → save PDF.
## Test Organization
- Tests mirror source structure. `src/foo/bar.ext` → `tests/foo/test_bar.ext` (adjust for language conventions).
- Test filenames start with `test_` or end with `_test` per language convention.
- Each test has a descriptive name explaining what behavior is being verified.
## Visual Verification
When changes affect UI rendering (canvas drawing, overlay positioning, layout, visual states) — any change to `src/ui/canvas/`, overlay drawing, coordinate math, or visual state transitions — verify visually with the screenshot tool before claiming completion. See `docs/screenshot-tool.md`.
## System Utility Tests
- Unit tests for utility wrappers must work without the utility installed (mock the subprocess call).
- Integration tests may require the utility and should be marked/tagged as such.
- Always test the error path: what happens when the utility is not installed?
~~~

(A `tdd.md` rule is the natural fifth file: a 2–3 line rule that states "use red/green TDD" and invokes the `test-driven-development` skill — or, if that skill does not exist, carries the red/green steps inline.)

## Plugin-repo mode — `.claude-plugin/plugin.json`

Scaffolded manifest; the only file inside `.claude-plugin/`, all component dirs sit at the plugin root.

~~~json
{
  "name": "my-plugin",
  "description": "One-line description shown in the plugin manager",
  "version": "1.0.0",
  "author": { "name": "Author Name" }
}
~~~
