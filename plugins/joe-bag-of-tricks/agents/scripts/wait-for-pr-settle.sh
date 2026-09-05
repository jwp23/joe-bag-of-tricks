#!/usr/bin/env bash
# wait-for-pr-settle.sh — the canonical PR-settle wait for branch-shepherd (and any
# other agent waiting on a single PR). Blocks in the foreground, polling until the
# PR's checks reach a terminal state or MAX_SECONDS elapses, then emits ONE line
# covering checks + CodeRabbit + mergeable so the caller never has to poll any of
# the three piecemeal or narrate elapsed time between waits.
#
# Dependency-free: gh and jq only.
#
# Usage: wait-for-pr-settle.sh <pr-number> [max-seconds] [poll-seconds]
#   max-seconds  default 600 — hard cap on the checks wait.
#   poll-seconds default 30  — interval between polls.
#
# Output (one JSON line):
#   {"checks":     "passed" | "failed" | "none" | "timeout",
#    "coderabbit": "success" | "pending" | "rate_limited" | "absent",
#    "mergeable":  "MERGEABLE" | "CONFLICTING" | "UNKNOWN"}
#
# checks:
#   passed  - every check reached a non-pending bucket and none failed
#   failed  - every check reached a non-pending bucket and at least one failed
#   none    - no check ever registered (repo has no PR-triggered checks, or the
#             PR has no merge ref yet — see mergeable below)
#   timeout - checks were still pending when max-seconds elapsed
#
# coderabbit:
#   success       - the CodeRabbit commit status on the PR's head SHA is success
#   pending       - the status is pending and no rate-limit comment was found
#   rate_limited  - a CodeRabbit comment on the PR mentions rate limiting; a
#                   rate-limited review must never block a merge — the caller
#                   escalates it, it does not wait longer for this to clear
#   absent        - no CodeRabbit commit status exists at all (app not installed,
#                   or not yet posted)
#
# mergeable is read once, after the checks wait, straight from `gh pr view`.

set -euo pipefail

pr="${1:?usage: wait-for-pr-settle.sh <pr-number> [max-seconds] [poll-seconds]}"
max_seconds="${2:-600}"
poll_seconds="${3:-30}"

elapsed=0
checks="timeout"
while [ "$elapsed" -lt "$max_seconds" ]; do
  bucket_json=$(gh pr checks "$pr" --json bucket 2>/dev/null || echo '[]')
  count=$(jq 'length' <<<"$bucket_json")
  if [ "$count" != "0" ]; then
    pending=$(jq '[.[] | select(.bucket == "pending")] | length' <<<"$bucket_json")
    if [ "$pending" = "0" ]; then
      failed=$(jq '[.[] | select(.bucket == "fail")] | length' <<<"$bucket_json")
      if [ "$failed" = "0" ]; then checks="passed"; else checks="failed"; fi
      break
    fi
  fi
  sleep "$poll_seconds"
  elapsed=$((elapsed + poll_seconds))
done

if [ "$checks" = "timeout" ]; then
  bucket_json=$(gh pr checks "$pr" --json bucket 2>/dev/null || echo '[]')
  count=$(jq 'length' <<<"$bucket_json")
  # Nothing ever registered in the whole wait: not a slow check, a repo/PR with
  # none (or, per the CONFLICTING case, one whose merge ref never let workflows fire).
  [ "$count" = "0" ] && checks="none"
fi

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
head_sha=$(gh pr view "$pr" --json headRefOid --jq .headRefOid)
coderabbit=$(gh api "repos/$repo/commits/$head_sha/statuses" \
  --jq '[.[] | select(.context == "CodeRabbit")] | first | .state // "absent"' 2>/dev/null || echo "absent")

if [ "$coderabbit" = "pending" ]; then
  rate_limited=$(gh api "repos/$repo/issues/$pr/comments?per_page=100" \
    --jq '[.[] | select(.user.login | startswith("coderabbitai")) | select(.body | test("rate limit"; "i"))] | length' \
    2>/dev/null || echo 0)
  [ "$rate_limited" != "0" ] && coderabbit="rate_limited"
fi

mergeable=$(gh pr view "$pr" --json mergeable --jq .mergeable 2>/dev/null || echo "UNKNOWN")

jq -n --arg checks "$checks" --arg coderabbit "$coderabbit" --arg mergeable "$mergeable" \
  '{checks: $checks, coderabbit: $coderabbit, mergeable: $mergeable}'
