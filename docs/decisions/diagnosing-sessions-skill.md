# Vendor upstream's `diagnosing-superpowers` as `diagnosing-sessions`

## Decision

Vendor upstream superpowers v6.4.1's new `skills/diagnosing-superpowers/` (20 files: SKILL.md,
seven analyst prompts plus scrub/scrub-audit/similar-session/analyst-common, four references,
four templates) into the plugin as `skills/diagnosing-sessions/`, with a mechanical rebrand and
no change of substance:

- plugin name `superpowers` → `joe-bag-of-tricks` throughout; skill name and H1 renamed; the
  workspace is `~/.joe-bag-of-tricks/diagnosing-sessions/<session-id>/`;
- the issue search and `gh issue create` target `jwp23/joe-bag-of-tricks`; the `gh` command
  applies only the `bug` label and the no-`gh` fallback link carries no `?template=`, because this
  repository ships no `.github/` issue template and has no `automated-issue-report` label;
- the description drops "on any harness" and two parenthetical other-harness mentions are
  trimmed (Claude Code only). `references/session-discovery.md` at v7.0.0 is harness-neutral prose
  with no per-harness subsections, so nothing was removed from it.

Classified `patched` in `docs/customizations.md`.

## Rationale

Nothing like it ships in the plugin. The repo's `.claude/scripts/extract-agent-transcripts.sh` is
authoring-only and installs nowhere. Transcripts are per-machine (the v1.9.4 investigation went
wrong on exactly that), so a diagnosis has to run where the session ran; this skill does, produces
a report where every finding cites `path:line`, and on request builds a scrubbed, approved bundle
and a GitHub issue — the handoff from the machine that saw the failure to the one that fixes it.

Cost: its description is long and lives in the always-loaded surface; the budget gate passed with
the skill present (205 tokens of headroom at the time). The awkward "non-joe-bag-of-tricks plugin"
phrasing in `prompts/skill-timeline.md` is the mechanical result of the rename and was left so the
file keeps diff-merging against upstream.
