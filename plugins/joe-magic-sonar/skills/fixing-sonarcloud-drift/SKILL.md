---
name: fixing-sonarcloud-drift
description: Use when SonarCloud reports open issues or unreviewed security hotspots on a long-lived branch - a drift tracking issue was opened by CI, a scan went red on main, or a repo on the free plan needs overall-code quality enforced that its pull-request gate does not cover
---

# Fixing SonarCloud Drift

## Overview

SonarCloud's free plan has **no custom quality gate**. Its built-in gate grades *new code* on a
pull request and says nothing about the state of the branch as a whole. So a project can hold a
green PR gate forever while overall-code findings pile up on `main`, unenforced and unnoticed.

**Core principle:** drift is enforced by an out-of-band audit, and every finding is closed by a
*decision on the record* — fixed, or accepted with a stated reason. Never by making the check stop
asking.

## When to Use

- A "SonarCloud drift on main" style tracking issue was opened or refreshed by CI
- A post-merge scan on a long-lived branch went red
- Setting up overall-code enforcement on a repo whose SonarCloud plan has no custom gate
- Not for: a failing PR gate on your own new code — that is ordinary review feedback, fix it in the branch

## The Loop

| Stage | Mechanism |
|-------|-----------|
| Pull requests | SonarCloud's free **new-code** gate. Unchanged, still authoritative for a PR |
| After a merge | The scan runs on the long-lived branch, then an `audit` job queries the API |
| Drift found | Audit **fails the job** and opens or refreshes **one** tracking issue |
| Branch clean | The same audit **closes** that issue automatically |
| Durable record | Your task tracker, not the GitHub issue — that issue is transient |

[sonar-audit.sh](sonar-audit.sh) is the audit. It counts unresolved issues
(`api/issues/search?resolved=false`) plus hotspots at `status=TO_REVIEW`, prints one summary line
plus a line per finding, and exits **1** when either count is non-zero.

```
SONAR_TOKEN=... ./sonar-audit.sh --report-only        # local check, never touches GitHub
SONAR_TOKEN=... GH_TOKEN=... ./sonar-audit.sh --branch main   # CI: fail + tracking issue
```

`--report-only` is implied whenever `GH_TOKEN` is unset, so a local run cannot file an issue by
accident. See `--help` for the rest.

## Two Mechanics That Decide Your Ordering

**The audit runs on a push to the long-lived branch.** It is not a PR job and, unless you add a
`workflow_dispatch` trigger yourself, there is no button to re-run it on demand. Do not plan around
one you have not confirmed exists in the workflow file.

**Resolving a finding in the SonarCloud UI counts as clean without any code change** — a
`falsepositive`/`accept` mark sets `resolved=true`, and a reviewed hotspot leaves `TO_REVIEW`.
Consequence: **do every SonarCloud-side marking before the fix PR merges.** Otherwise the single
post-merge audit sees leftover findings, stays red, and the tracking issue sits open looking like
unresolved drift with nothing left to push.

## Three Dispositions — the Hard Part

This is where the judgment lives, and where agents go wrong in both directions.

| Disposition | When | How |
|---|---|---|
| **Fix the code** | The finding is right | On a branch. Behavior change → test first |
| **Mark it in SonarCloud** | The analyzer's precondition genuinely does not hold here | `falsepositive` (analyzer is wrong) or `accept` (correct but deliberately taken). Record the rationale in your tracker's memory so a later session does not re-litigate it |
| **Narrow config exclusion** | The *same* false positive keeps recurring structurally — a new one every time the pattern is used | A file- and rule-scoped `sonar.issue.ignore.multicriteria` entry in `sonar-project.properties`, with a comment saying why. Only after marking it once and watching it come back |

**Never** silence a rule to make it pass: no blanket rule disable, no `//NOSONAR` sprinkled to get
green, no widening an exclusion past the one file and one rule that earned it.

A hotspot is a *question*, not a defect. Its intended terminal state is a documented review.
Marking one `SAFE` requires naming the specific reason it cannot be exploited here; "looks fine" is
not a review, and a hotspot you cannot decide is one to ask your human partner about.

## Procedure

1. **Verify the report against live state first.** The tracking issue body is a snapshot from the
   last push and may name findings already resolved, or files that do not exist. Re-query before
   planning work — a run that fixes phantom findings is worse than no run.
2. **File the round in your tracker** and claim it. This is the durable record; the GitHub issue is
   transient and will close itself.
3. **Read the rule, then the code, for each finding.** Decide its disposition from the three above.
   Argue yourself out of "false positive" before you accept it — if you cannot state the analyzer's
   precondition and show it does not hold, it is a real finding you dislike.
4. **Land the SonarCloud markings**, then merge the fix PR, in that order.
5. **Watch the post-merge audit.** Clean means the tracking issue closes itself. Still red means a
   marking did not stick, a finding was missed, or your fix introduced a new one — diagnose it,
   never re-run and hope.
6. **Close the tracker item** with what was fixed, what was accepted and why, and the PR number.

## Red Flags — STOP

- Resolving findings in bulk to turn the job green
- Marking a false positive you cannot explain in one checkable sentence
- Reaching for a config exclusion on a finding's *first* appearance
- Closing the tracking issue by hand — it is the audit's to close, and it re-opens if drift is real
- Treating a green PR gate as evidence the branch is clean; it grades new code only
- Planning around a re-run trigger you have not read in the workflow file

## New Repo Setup

`sonar-audit.sh` reads `sonar.projectKey` from `sonar-project.properties` and needs no editing;
pass `--project` to override. Wire it as a job that `needs` the scan and is conditioned on a push
to the long-lived branch, with `issues: write` permission, `SONAR_TOKEN`, and `GH_TOKEN`. Set
`sonar.qualitygate.wait=true` on the scan so analysis has landed before the audit queries it.
