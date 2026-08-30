# Fixing SonarCloud Drift: a Skill Plus a Parameterized Audit Script

## Decision

The SonarCloud overall-code drift loop ships as a new fork-original skill,
`plugins/joe-bag-of-tricks/skills/fixing-sonarcloud-drift/` (SKILL.md + `sonar-audit.sh`),
extracted from throwntom's `CLAUDE.md` "SonarCloud Drift (Required)" section and its
`tools/sonar-audit.sh`.

`sonar-audit.sh` is bundled as a reusable tool, not merely described. It is throwntom's script with
the hardcoded project key removed: the key now comes from `--project` or from `sonar.projectKey` in
`sonar-project.properties`, the host from `SONAR_HOST`, and the tracking-issue title is derived from
the audited branch. Its issue body no longer names beads or a specific `CLAUDE.md` section.

The skill names **three** dispositions for a finding — fix, mark in SonarCloud, or a narrow
file-and-rule-scoped `sonar.issue.ignore.multicriteria` exclusion — where the CLAUDE.md prose named
only two.

The tracker is described generically ("your task tracker", "your tracker's memory") rather than as
beads.

## Rationale

- The skill's ordering constraint is the non-obvious part and the reason it is worth writing down:
  a `falsepositive`/`accept` mark makes the audit clean *with no code change*, and the audit only
  runs on a push to the long-lived branch. So markings must land **before** the fix PR merges, or
  the one post-merge run stays red with nothing left to push. Neither baseline derived this
  reliably.
- Three dispositions, not two: throwntom marked `swift:S1075` a false positive per route constant
  until a new route re-flagged it, then landed a file-and-rule-scoped exclusion (commit `a70a451`).
  The prose forbade "weakening a rule" without distinguishing that narrow, reviewed exclusion from a
  blanket disable, so the escalation path had to be rediscovered. The skill states the trigger:
  only after marking it once and watching it recur structurally.
- Generic tracker wording, despite this plugin's other skills being beads-native: the beads-native
  skills (`writing-plans`, `executing-plans`, `subagent-driven-development`) orchestrate work whose
  data model *is* the bd hierarchy — epics, parents, `bd children`. This skill needs only "the round
  has a durable record with what was fixed, what was accepted, and the PR number", which any tracker
  satisfies. Naming `bd` would have made the skill read as inapplicable in a repo without it, and
  the rule it enforces would have been dropped along with the command. The plugin's *agents* already
  use "the project's issue tracker" for the same reason.
- The script is bundled rather than transcribed because a project re-deriving the two API queries,
  the `resolved=false` / `TO_REVIEW` clean test, and the open-refresh-close issue lifecycle would get
  them subtly wrong, and the exit-1-on-drift contract is what makes it usable as a CI gate.
- Verified against the real tooling, not from memory: flags (`--branch`, `--report-only`), the
  `GH_TOKEN`-unset implies `--report-only` behavior, the exit codes, the two API endpoints, and the
  `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` condition all come from
  throwntom's `tools/sonar-audit.sh` and `.github/workflows/sonarqube.yml`. The SonarCloud status
  vocabulary (`falsepositive`, `accept`, `reopen`; hotspot `REVIEWED` + `FIXED`/`SAFE`/`ACKNOWLEDGED`)
  comes from the SonarQube MCP tool schemas — a baseline agent guessed `FALSE_POSITIVE`/`ACCEPT`,
  which do not exist.
- The "no `workflow_dispatch` you have not confirmed" red flag exists because *both* baselines
  proposed re-triggering the audit that way, and the workflow has no such trigger.
- Cost if wrong: a bundled script that drifts from throwntom's copy. Accepted — the skill's copy is
  the parameterized one and throwntom's is expected to converge on it, not the reverse.

## Testing

Baselines were contaminated: both baseline agents ran with throwntom as their working directory and
read its `CLAUDE.md`, so they had the procedure under test in hand and performed well. The RED is
therefore weaker than the Iron Law wants. What it did establish, with the prose available, was three
reproducible defects the prose does not prevent: invented status values, a `workflow_dispatch`
trigger that does not exist, and no knowledge of the exclusion escalation. The skill closes all
three. A future clean baseline should run in a sandbox with no repo instruction file present.

## Update 2026-08-30: ships as its own plugin, `joe-magic-sonar`

Joe overruled the deferral (GH #74): the workflow is proving itself in throwntom, so the draft is
adopted now — but as a **fourth, separate plugin** (`plugins/joe-magic-sonar`), not inside
`joe-bag-of-tricks` as the draft above assumed.

Rationale:
- **Context budget.** A skill description in `joe-bag-of-tricks` enters the always-loaded surface
  of every session in every consuming project. SonarCloud drift triage is irrelevant to a project
  without SonarCloud; a separate plugin makes that cost opt-in per project, which is what the
  committed budget gate exists to protect.
- **No coupling.** The skill was already written standalone — generic tracker wording, no
  cross-references into `joe-bag-of-tricks` skills — so the one-unit constraint does not apply and
  nothing had to be rewritten for the move.
- **Established pattern.** The marketplace already ships `joe-magic-bootstrap` and
  `joe-magic-design` as separate optional plugins with per-plugin scoped release tags; this
  follows it (`joe-magic-sonar-v1.0.0`).

Trade-off accepted: one more plugin root to validate (its own `claude plugin validate` +
`verify-skills-load.sh --plugin-dir` gate lines) and one more release-tag series.

### Clean-sandbox baseline, run at adoption (2026-08-30)

The contaminated-baseline debt above was paid before shipping: RED/GREEN probes in a scratch
fixture (fake project, drift-issue snapshot with a real ReDoS, a recurring S1075 false positive,
and a `verify=False` hotspot; no project CLAUDE.md, no skill on RED). RED — the agent avoided two
of the three 2026-08-29 defects on its own (no invented re-run trigger, knew the exclusion
escalation) but **violated the ordering rule** (planned the hotspot marking after the merge) and
**never filed a durable tracker record**. GREEN (`--plugin-dir plugins/joe-magic-sonar`) — both
gaps closed: tracker round filed at step 0, "all before the fix PR merges" stated and ordered,
narrow exclusion on recurrence, SAFE refused without a checkable reason, and the missing
`sonar.qualitygate.wait=true` caught per the skill's setup section. The skill's remaining
marginal value is concentrated in the ordering constraint and the durable-record rule — exactly
the two lines the original extraction argued were the non-obvious part.
