# ADR-004: Vendor `using-git-worktrees` Wholesale

## Context

`using-git-worktrees` arrived in the initial import (`b3b7c04`) as a copy of upstream's
then-current skill and was classified `patched`. At v6.1.1 upstream **rewrote** it around a new
spine:

1. Detect existing isolation (Step 0).
2. Prefer the platform's **native** worktree tool (`EnterWorktree`, `WorktreeCreate`, a `/worktree`
   command, a `--worktree` flag) — Step 1a.
3. Fall back to `git worktree add` only when no native tool exists — Step 1b.

Plus a consent prompt before creating a worktree, a sandbox-permission fallback, and a directory
priority of *explicit instructions > existing project-local directory > `.worktrees/` default*.

The v6.1.1 sync ported **only** the Step 0 detection block and declined the rest, recording the
skip as "fork convention, verified-functional." That left the file carrying upstream's pre-v6.1.1
structure — Directory Selection Process, Safety Verification, numbered Creation Steps, the
`~/.local/share/worktrees` global-directory branch, Example Workflow, Integration — none of which
upstream still has. Two concrete defects followed:

- **Self-contradiction.** The Directory Selection section said default to `.worktrees/` and
  explicitly "Do not ask the user," while the Quick Reference table one screen below said
  `Neither exists | Check CLAUDE.md → Ask user`. The table also contradicted
  `.claude/rules/git-workflow.md`.
- **Declined native-tool deferral.** `EnterWorktree` is a real tool in this harness. Upstream calls
  bypassing a native tool "the #1 mistake — it creates phantom state your harness can't see or
  manage." The recorded justification ("do not ask") covered the *consent* half of the skip but
  never the *native-tool* half; those were two separate divergences collapsed into one note.

The v6.1.1 skip was therefore not a considered rejection of native tools — it was a partial port
whose rationale only fit one of the two things it skipped.

## Decision

Take upstream's `skills/using-git-worktrees/SKILL.md` **wholesale at v6.2.0** and reclassify the
file `patched` → `vendored`. Future syncs take head with no reconciliation.

Both defects are fixed by the vendored text itself: the Quick Reference row now reads
`Neither exists | Check instruction file, then default .worktrees/` (consistent with the fork
convention), and Step 1a restores the native-tool deferral.

The one genuine tension — upstream's consent prompt vs. the fork's do-not-ask convention — is
resolved **outside the skill**, so the skill stays byte-identical to upstream. Upstream's own
wording is "Honor any existing declared preference without asking," so
`.claude/rules/git-workflow.md` now declares that preference explicitly: isolate without asking,
always `.worktrees/`, prefer a native worktree tool. The consent prompt self-suppresses in this
repo.

## Trade-offs

**Chosen: vendor wholesale, express the fork convention in the rules file**

- Removes a `patched` row — one less file needing hand-reconciliation every sync.
- Fixes the contradictory Quick Reference row and the stale `~/.local/share/worktrees` branch for
  free, rather than as separate hand-edits to a diverged file.
- Restores the native-tool deferral, so worktree state stays visible to the harness that created
  it.
- Puts the fork convention where conventions belong (`.claude/rules/`), not smuggled into an
  inherited skill body — which is exactly what `.claude/rules/git-workflow.md` already forbids:
  "NEVER edit an upstream file to express a divergent workflow."
- Cost: the fork no longer controls this skill's prose. An upstream change to worktree placement
  arrives automatically and could conflict with the `.worktrees/` convention; the rules file, not
  the skill, is where we'd notice and correct it.

**Rejected: keep `patched`, hand-fix the two defects**

- Preserves fork control, but re-earns the same reconciliation cost on every future sync for a file
  with no remaining fork-specific *content* — only a fork-specific *convention*, which lives better
  in the rules file.
- Leaves the pre-v6.1.1 spine (global-directory branch, Example Workflow, Integration) diverging
  further from upstream with each release, for no benefit.

**Rejected: vendor, but patch out the consent prompt**

- Would reintroduce a one-line divergence — and therefore a permanent merge conflict site — to say
  something upstream already accommodates via "honor any existing declared preference."
- Violates the standing rule against editing an upstream file to express a divergent workflow.
